import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/busy_overlay.dart';
import 'package:krate/ui/widgets/managed_episode_tile.dart';

class SeriesEpisodePickerScreen extends ConsumerStatefulWidget {
  final int tmdbId;
  const SeriesEpisodePickerScreen({super.key, required this.tmdbId});

  @override
  ConsumerState<SeriesEpisodePickerScreen> createState() =>
      _SeriesEpisodePickerScreenState();
}

class _SeriesEpisodePickerScreenState
    extends ConsumerState<SeriesEpisodePickerScreen> {
  final Map<String, String> _selectedFiles = {}; // "S{season}E{ep}" -> filePath
  bool _isLoadingTmdb = true;
  bool _isPickingFile = false;
  Content? _content;
  List<Map<String, dynamic>> _tmdbEpisodes = [];

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    setState(() => _isLoadingTmdb = true);
    try {
      final repo = ref.read(contentRepoProvider);
      _content = await repo.getByTmdbId(widget.tmdbId);

      final tmdb = ref.read(tmdbServiceProvider);
      if (_content == null) {
        final data = await tmdb.getSeriesDetails(widget.tmdbId);
        _content = Content.fromTmdbSeries(data);
      }

      // Load episodes from TMDB to ensure we have the full list even if not in DB
      _tmdbEpisodes = [];
      for (int s = 1; s <= _content!.totalSeasons; s++) {
        final seasonData = await tmdb.getSeasonDetails(widget.tmdbId, s);
        final epList = (seasonData['episodes'] as List?) ?? [];
        for (final ep in epList) {
          _tmdbEpisodes.add(ep as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint('[SeriesEpisodePicker] Error loading: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTmdb = false);
    }
  }

  Future<void> _refreshFromTmdb() async {
    if (_content == null) return;
    setState(() => _isLoadingTmdb = true);
    try {
      // We can use a simplified version of importSeries logic to just fetch/refresh metadata
      final tmdb = ref.read(tmdbServiceProvider);
      final data = await tmdb.getSeriesDetails(widget.tmdbId);
      final updatedContent = Content.fromTmdbSeries(
        data,
      ).copyWith(id: _content!.id);
      await ref.read(contentRepoProvider).update(updatedContent);

      final epRepo = ref.read(episodeRepoProvider);
      for (int s = 1; s <= updatedContent.totalSeasons; s++) {
        final seasonData = await tmdb.getSeasonDetails(widget.tmdbId, s);
        final epList = (seasonData['episodes'] as List?) ?? [];
        for (final eData in epList) {
          final epData = eData as Map<String, dynamic>;
          final epNum = epData['episode_number'] as int? ?? 0;
          final existingEp = await epRepo.getSeriesEpisode(
            _content!.id!,
            s,
            epNum,
          );
          if (existingEp == null) {
            await epRepo.insert(Episode.fromTmdbEpisode(epData, _content!.id!));
          } else {
            await epRepo.update(
              Episode.fromTmdbEpisode(epData, _content!.id!).copyWith(
                id: existingEp.id,
                videoPath: existingEp.videoPath,
                fileStatus: existingEp.fileStatus,
              ),
            );
          }
        }
      }
      ref.invalidate(contentEpisodesProvider(_content!.id!));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Refreshed from TMDB')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Refresh failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingTmdb = false);
    }
  }

  Future<void> _pickSingle(int season, int epNum) async {
    setState(() => _isPickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mkv', 'avi', 'mov', 'wmv'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFiles['S${season}E$epNum'] = result.files.single.path!;
        });
      }
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  void _onImport() {
    if (_content == null || _selectedFiles.isEmpty) return;

    // Convert flat map to season-based map for ImportService
    final Map<int, Map<int, String>> mappedFiles = {};
    for (final entry in _selectedFiles.entries) {
      final match = RegExp(r'S(\d+)E(\d+)').firstMatch(entry.key);
      if (match != null) {
        final season = int.parse(match.group(1)!);
        final ep = int.parse(match.group(2)!);
        mappedFiles.putIfAbsent(season, () => {})[ep] = entry.value;
      }
    }

    ref
        .read(importJobsProvider.notifier)
        .importSeries(
          service: ref.read(importServiceProvider),
          content: _content!,
          episodeFiles: mappedFiles,
        );

    // Pop back to root (Home) as requested
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (_content == null && _isLoadingTmdb) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_content == null) {
      return const Scaffold(body: Center(child: Text('Failed to load series')));
    }

    // Group TMDB episodes by season
    final seasons = <int, List<Map<String, dynamic>>>{};
    for (final ep in _tmdbEpisodes) {
      final s = ep['season_number'] as int? ?? 0;
      seasons.putIfAbsent(s, () => []).add(ep);
    }
    final sortedSeasons = seasons.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text('Import ${_content!.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingTmdb ? null : _refreshFromTmdb,
            tooltip: 'Refresh from TMDB',
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: sortedSeasons.length,
            itemBuilder: (context, index) {
              final seasonNum = sortedSeasons[index];
              final seasonEpisodes = seasons[seasonNum]!
                ..sort(
                  (a, b) => (a['episode_number'] as int? ?? 0).compareTo(
                    b['episode_number'] as int? ?? 0,
                  ),
                );

              return Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    'Season $seasonNum',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  initiallyExpanded: index == 0,
                  children: seasonEpisodes.map((epData) {
                    final epNum = epData['episode_number'] as int? ?? 0;
                    final key = 'S${seasonNum}E$epNum';
                    final filePath = _selectedFiles[key];

                    // Try to find if this episode is already in library (if content.id exists)
                    // This is optional but nice. For now we just show it as a picker.
                    return ManagedEpisodeTile(
                      episode: Episode(
                        contentId: _content!.id ?? -1,
                        seasonNumber: seasonNum,
                        episodeNumber: epNum,
                        title: epData['name'] as String?,
                        description: epData['overview'] as String?,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                      mode: ManagedTileMode.normal,
                      stagedFile: filePath != null
                          ? StagedFile(
                              episodeId: -1, // Not used here for linking
                              path: filePath,
                              isReplace: false, // Always false in New Import
                            )
                          : null,
                      onImport: () => _pickSingle(seasonNum, epNum),
                      onRemoveFile: () =>
                          setState(() => _selectedFiles.remove(key)),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          if (_isLoadingTmdb)
            const BusyOverlay(message: 'Syncing with TMDB...'),
          if (_isPickingFile)
            const BusyOverlay(message: 'Accessing storage...'),
        ],
      ),
      bottomNavigationBar: _selectedFiles.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _onImport,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: Text('Import ${_selectedFiles.length} Episodes'),
                ),
              ),
            )
          : null,
    );
  }
}
