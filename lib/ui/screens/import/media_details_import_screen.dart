import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:krate/core/constants.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/providers/providers.dart';

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
        context.pop();
      }
    }
  }

  bool _isBusy = false;

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
      // Go to Episode Picker for series
      context.push('/import/picker/${_content!.tmdbId}');
      return;
    }

    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video file first')),
      );
      return;
    }

    // Trigger Import (Sync/Non-blocking from UI perspective)
    ref
        .read(importJobsProvider.notifier)
        .importMovie(
          service: ref.read(importServiceProvider),
          content: _content!,
          sourceFilePath: _selectedFilePath!,
        );

    // Immediate redirect to Home
    context.go('/');
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
              children: [
                // Preview Card
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_content!.tmdbPosterPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          '$kTmdbImageBase/w185${_content!.tmdbPosterPath}',
                          width: 120,
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
                              '${_content!.releaseDate!.year} • ${widget.type.name.toUpperCase()}',
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

                if (widget.type == ContentType.movie) ...[
                  const Divider(),
                  ListTile(
                    title: const Text('Source File'),
                    subtitle: Text(_selectedFilePath ?? 'Not selected'),
                    trailing: const Icon(Icons.file_open),
                    onTap: _pickFile,
                  ),
                  const Divider(),
                ],

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isBusy ? null : _onConfirmImport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.type == ContentType.movie
                        ? 'Import Movie'
                        : 'Select Episodes',
                  ),
                ),
              ],
            ),
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
