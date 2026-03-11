import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/busy_overlay.dart';
import 'package:krate/ui/screens/import/series_episode_picker_screen.dart';

class MediaDetailsImportScreen extends ConsumerStatefulWidget {
  final int tmdbId;
  final ContentType type;

  const MediaDetailsImportScreen({
    super.key,
    required this.tmdbId,
    required this.type,
  });

  @override
  ConsumerState<MediaDetailsImportScreen> createState() =>
      _MediaDetailsImportScreenState();
}

class _MediaDetailsImportScreenState
    extends ConsumerState<MediaDetailsImportScreen> {
  Content? _content;
  bool _isLoading = true;
  bool _isBusy = false;
  String? _selectedFilePath;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final tmdb = ref.read(tmdbServiceProvider);
      final data = widget.type == ContentType.movie
          ? await tmdb.getMovieDetails(widget.tmdbId)
          : await tmdb.getSeriesDetails(widget.tmdbId);

      _content = widget.type == ContentType.movie
          ? Content.fromTmdbMovie(data)
          : Content.fromTmdbSeries(data);

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load details: $e')));
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _pickFile() async {
    setState(() => _isBusy = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (result != null && result.files.single.path != null) {
        setState(() => _selectedFilePath = result.files.single.path);
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _onConfirmImport() {
    if (_content == null) return;

    if (widget.type == ContentType.series) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              SeriesEpisodePickerScreen(tmdbId: _content!.tmdbId!),
        ),
      );
      return;
    }

    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video file first')),
      );
      return;
    }

    ref
        .read(importJobsProvider.notifier)
        .importMovie(
          service: ref.read(importServiceProvider),
          content: _content!,
          sourceFilePath: _selectedFilePath!,
        );

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _content == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_content!.title)),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Preview ──────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_content!.tmdbPosterPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          '$kTmdbImageBase/w185${_content!.tmdbPosterPath}',
                          width: 110,
                        ),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _content!.title,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          if (_content!.releaseDate != null)
                            Text(
                              '${_content!.releaseDate!.year} • '
                              '${widget.type.name.toUpperCase()}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            _content!.description ?? '',
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── File picker (movies) ──────────────────────────────────
                if (widget.type == ContentType.movie) ...[
                  Card(
                    child: ListTile(
                      title: const Text('Source File'),
                      subtitle: Text(
                        _selectedFilePath?.split('/').last ?? 'Not selected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      leading: const Icon(Icons.file_open_outlined),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickFile,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Action ────────────────────────────────────────────────
                FilledButton.icon(
                  onPressed: _isBusy ? null : _onConfirmImport,
                  icon: Icon(
                    widget.type == ContentType.movie
                        ? Icons.download_outlined
                        : Icons.list_alt,
                  ),
                  label: Text(
                    widget.type == ContentType.movie
                        ? 'Import Movie'
                        : 'Select Episodes',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ],
            ),
          ),
          if (_isBusy)
            const BusyOverlay(message: 'Accessing storage…', showBlur: false),
        ],
      ),
    );
  }
}
