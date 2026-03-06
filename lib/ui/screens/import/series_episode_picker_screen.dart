import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/providers/providers.dart';

class SeriesEpisodePickerScreen extends ConsumerStatefulWidget {
  final int tmdbId;

  const SeriesEpisodePickerScreen({super.key, required this.tmdbId});

  @override
  ConsumerState<SeriesEpisodePickerScreen> createState() =>
      _SeriesEpisodePickerScreenState();
}

class _SeriesEpisodePickerScreenState
    extends ConsumerState<SeriesEpisodePickerScreen> {
  Content? _content;
  final Map<int, List<Map<String, dynamic>>> _seasons = {};
  final Map<int, Map<int, String>> _selectedFiles =
      {}; // season -> episode -> path
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllSeasons();
  }

  Future<void> _loadAllSeasons() async {
    try {
      final tmdb = ref.read(tmdbServiceProvider);
      final details = await tmdb.getSeriesDetails(widget.tmdbId);
      _content = Content.fromTmdbSeries(details);

      final seasonCount = details['number_of_seasons'] as int? ?? 0;
      for (int i = 1; i <= seasonCount; i++) {
        final sData = await tmdb.getSeasonDetails(widget.tmdbId, i);
        final eps =
            (sData['episodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _seasons[i] = eps;
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        context.pop();
      }
    }
  }

  bool _isBusy = false;

  Future<void> _pickFile(int season, int episode) async {
    setState(() => _isBusy = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFiles.putIfAbsent(season, () => {})[episode] =
              result.files.single.path!;
        });
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _onImport() {
    if (_content == null || _selectedFiles.isEmpty) return;

    ref
        .read(importJobsProvider.notifier)
        .importSeries(
          service: ref.read(importServiceProvider),
          content: _content!,
          episodeFiles: _selectedFiles,
        );

    context.go('/'); // Immediate redirect to Home
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final sortedSeasons = _seasons.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Episodes: ${_content?.title}'),
        actions: [
          TextButton(
            onPressed: (_selectedFiles.isNotEmpty && !_isBusy)
                ? _onImport
                : null,
            child: const Text('IMPORT'),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: sortedSeasons.length,
            itemBuilder: (context, index) {
              final sNum = sortedSeasons[index];
              final sEps = _seasons[sNum]!;

              return ExpansionTile(
                title: Text('Season $sNum (${sEps.length} episodes)'),
                initiallyExpanded: index == 0,
                children: sEps.map((ep) {
                  final epNum = ep['episode_number'] as int;
                  final path = _selectedFiles[sNum]?[epNum];

                  return ListTile(
                    title: Text('$epNum. ${ep['name'] ?? ''}'),
                    subtitle: Text(
                      path != null
                          ? PathUtils.basename(path)
                          : 'No file selected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      path != null
                          ? Icons.check_circle
                          : Icons.add_circle_outline,
                      color: path != null ? Colors.green : null,
                    ),
                    onTap: _isBusy ? null : () => _pickFile(sNum, epNum),
                  );
                }).toList(),
              );
            },
          ),
          if (_isBusy)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Accessing storage...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Minimal path dependency for basename
class PathUtils {
  static String basename(String path) => path.split(RegExp(r'[/\\]')).last;
}
