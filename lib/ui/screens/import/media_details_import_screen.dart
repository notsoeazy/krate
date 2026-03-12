import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/utils/errors.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/busy_overlay.dart';
import 'package:krate/ui/widgets/media_import_preview.dart';
import 'package:krate/ui/widgets/file_picker_tile.dart';
import 'package:krate/ui/screens/import/series_episode_picker_screen.dart';
import 'package:krate/utils/file_utils.dart';

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
  List<String> _subtitlePaths = [];

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

  Future<void> _pickFiles() async {
    try {
      final picked = await FileUtils.pickVideoWithSubtitles(
        debugLabel: 'MediaDetailsImport',
      );

      if (picked != null) {
        setState(() {
          _selectedFilePath = picked.videoPath;
          _subtitlePaths = picked.subtitlePaths;
        });
      }
    } on KrateException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _pickAdditionalSubtitles() async {
    setState(() => _isBusy = true);
    try {
      final paths = await FileUtils.pickSubtitlesOnly(
        debugLabel: 'MediaDetailsImport',
      );
      if (paths != null) {
        setState(() {
          _subtitlePaths = {..._subtitlePaths, ...paths}.toList();
        });
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _onClear() {
    setState(() {
      _selectedFilePath = null;
      _subtitlePaths = [];
    });
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
          subtitlePaths: _subtitlePaths,
        );

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _content == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(_content!.title)),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview
                MediaImportPreview(
                  content: _content!,
                  type: widget.type,
                ),

                const SizedBox(height: 32),

                // File Picker
                if (widget.type == ContentType.movie) ...[
                  FilePickerTile(
                    selectedFilePath: _selectedFilePath,
                    subtitlePaths: _subtitlePaths,
                    onPickFiles: _pickFiles,
                    onPickSubtitles: _pickAdditionalSubtitles,
                    onClear: _onClear,
                  ),
                  const SizedBox(height: 24),
                ],

                // Actions
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
