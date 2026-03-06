import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:krate/services/api/tmdb_service.dart';
import 'package:krate/services/api/api_service.dart';
import 'package:krate/models/api/episode_api.dart';
import 'package:krate/models/app/episode.dart';
import 'package:krate/repositories/episode_repository.dart';
import 'package:krate/services/import_service.dart';
import 'package:krate/models/app/content.dart';

class SeriesEpisodePickerScreen extends StatefulWidget {
  final Content content; // Prepared from series details

  const SeriesEpisodePickerScreen({super.key, required this.content});

  @override
  State<SeriesEpisodePickerScreen> createState() =>
      _SeriesEpisodePickerScreenState();
}

class _SeriesEpisodePickerScreenState extends State<SeriesEpisodePickerScreen> {
  int _selectedSeason = 1;
  bool _isLoading = false;
  List<EpisodeApi> _episodes = [];
  Map<int, bool> _alreadyImported = {}; // episodeNumber -> exists
  String? _error;

  // Map<Season, Map<Episode, FilePath>>
  final Map<int, Map<int, String>> _mappedFiles = {};

  @override
  void initState() {
    super.initState();
    _fetchEpisodes();
  }

  Future<void> _fetchEpisodes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tmdb = context.read<TMDBService>();
      final episodeRepo = context.read<EpisodeRepository>();

      final results = await Future.wait([
        tmdb.getSeasonDetails(widget.content.tmdbId!, _selectedSeason),
        widget.content.id != null
            ? episodeRepo.getEpisodesBySeason(
                widget.content.id!,
                _selectedSeason,
              )
            : Future.value(<Episode>[]),
      ]);

      final data = results[0] as Map<String, dynamic>;
      final existing = results[1] as List<Episode>;

      final list = data['episodes'] as List? ?? [];
      final importedMap = {
        for (final e in existing) e.episodeNumber: e.videoPath != null,
      }.cast<int, bool>();

      if (mounted) {
        setState(() {
          _episodes = list
              .map((e) => EpisodeApi.fromMap(e as Map<String, dynamic>))
              .toList();
          _alreadyImported = importedMap;
          _isLoading = false;
        });
      }
    } on KrateNetworkException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "An unexpected error occurred: $e";
          _isLoading = false;
        });
      }
    }
  }

  bool _isPickingFile = false;

  Future<void> _pickFile(int episodeNumber) async {
    if (_isPickingFile) return;

    final importService = context.read<ImportService>();
    if (importService.isImporting) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cannot pick files while an import is in progress."),
          ),
        );
      }
      return;
    }

    setState(() => _isPickingFile = true);

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        dialogTitle: "Select Episode $episodeNumber",
      );
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }

    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    final allowed = ['mp4', 'mkv', 'avi', 'mov', 'webm'];
    final ext = path.split('.').last.toLowerCase();

    if (!allowed.contains(ext)) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Unsupported Format"),
            content: Text(
              "The file extension '.$ext' is not officially supported. "
              "Please select one of the following: ${allowed.join(', ')}",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() {
      _mappedFiles[_selectedSeason] ??= {};
      _mappedFiles[_selectedSeason]![episodeNumber] = path;
    });
  }

  Future<void> _startSeriesImport() async {
    if (_mappedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please pick at least one episode file.")),
      );
      return;
    }

    try {
      final importService = context.read<ImportService>();
      if (importService.isImporting) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("An import is already in progress.")),
          );
        }
        return;
      }

      // Trigger background import
      importService.importSeries(widget.content, _mappedFiles);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Import started for '${widget.content.title}'"),
          ),
        );
        if (widget.content.id != null) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to start import: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Map Episodes: ${widget.content.title}"),
        actions: [
          if (_mappedFiles.isNotEmpty)
            TextButton(
              onPressed: context.watch<ImportService>().isImporting
                  ? null
                  : _startSeriesImport,
              child: const Text("FINISH"),
            ),
        ],
      ),
      body: Column(
        children: [
          // Season Selector
          if (widget.content.totalSeasons > 1)
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: widget.content.totalSeasons,
                itemBuilder: (context, index) {
                  final season = index + 1;
                  final isSelected = _selectedSeason == season;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text("Season $season"),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedSeason = season);
                          _fetchEpisodes();
                        }
                      },
                    ),
                  );
                },
              ),
            ),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator())),

          if (!_isLoading && _error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: theme.colorScheme.error.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchEpisodes,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (!_isLoading && _error == null)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _episodes.length,
                itemBuilder: (context, index) {
                  final ep = _episodes[index];
                  final filePath =
                      _mappedFiles[_selectedSeason]?[ep.episodeNumber];
                  final isMapped = filePath != null;
                  final isImported =
                      _alreadyImported[ep.episodeNumber] ?? false;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    title: Text(
                      "Episode ${ep.episodeNumber}: ${ep.name}",
                      style: TextStyle(
                        color: isImported ? Colors.white70 : null,
                      ),
                    ),
                    subtitle: Text(
                      isImported
                          ? (isMapped
                                ? "Updating: ${filePath.split('/').last}"
                                : "Already in Library")
                          : (isMapped
                                ? filePath.split('/').last
                                : "No file selected"),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isImported
                            ? (isMapped ? Colors.orangeAccent : Colors.white24)
                            : (isMapped ? Colors.green : Colors.white24),
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isImported && !isMapped)
                          const Icon(Icons.check_circle, color: Colors.white24),
                        IconButton(
                          icon: Icon(
                            isMapped ? Icons.edit : Icons.add_circle_outline,
                            color: isMapped ? theme.colorScheme.primary : null,
                          ),
                          onPressed: () => _pickFile(ep.episodeNumber),
                          tooltip: isImported ? "Change File" : "Select File",
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
