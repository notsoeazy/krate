import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:krate/services/api/tmdb_service.dart';
import 'package:krate/services/api/api_service.dart';
import 'package:krate/models/api/movie_api.dart';
import 'package:krate/models/api/tv_series_api.dart';
import 'package:krate/models/app/content.dart';
import 'package:krate/services/import_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:krate/screens/import/series_episode_picker_screen.dart';

class MediaDetailsImportScreen extends StatefulWidget {
  final int tmdbId;
  final String type; // 'movie' or 'tv'

  const MediaDetailsImportScreen({
    super.key,
    required this.tmdbId,
    required this.type,
  });

  @override
  State<MediaDetailsImportScreen> createState() =>
      _MediaDetailsImportScreenState();
}

class _MediaDetailsImportScreenState extends State<MediaDetailsImportScreen> {
  bool _isLoading = true;
  dynamic _details; // MovieApi or TvSeriesApi
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tmdb = context.read<TMDBService>();
      if (widget.type == 'movie') {
        final map = await tmdb.getMovieDetails(widget.tmdbId);
        _details = MovieApi.fromMap(map);
      } else {
        final map = await tmdb.getTVDetails(widget.tmdbId);
        _details = TvSeriesApi.fromMap(map);
      }
      if (mounted) setState(() => _isLoading = false);
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

  Future<void> _startImportFlow() async {
    if (widget.type == 'movie') {
      await _importMovie();
    } else {
      final seriesApi = _details as TvSeriesApi;
      final content = Content.fromSeriesApi(seriesApi);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SeriesEpisodePickerScreen(content: content),
          ),
        );
      }
    }
  }

  bool _isPickingFile = false;

  Future<void> _importMovie() async {
    if (_isPickingFile) return;

    final importService = context.read<ImportService>();
    if (importService.isImporting) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("An import is already in progress.")),
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
        dialogTitle: "Select Movie File",
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

    try {
      final movieApi = _details as MovieApi;
      final content = Content.fromMovieApi(movieApi);

      // Trigger background import (non-blocking for THIS screen)
      importService.importMovie(content, path);

      if (mounted) {
        Navigator.of(context).pop(true); // Return home/search immediately
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Import started for '${content.title}'")),
        );
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.signal_wifi_off_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _fetchDetails,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Retry Fetching Details"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final title = widget.type == 'movie'
        ? (_details as MovieApi).title
        : (_details as TvSeriesApi).name;
    final backdropPath = widget.type == 'movie'
        ? (_details as MovieApi).backdropPath
        : (_details as TvSeriesApi).backdropPath;
    final overview = widget.type == 'movie'
        ? (_details as MovieApi).overview
        : (_details as TvSeriesApi).overview;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: backdropPath != null
                  ? CachedNetworkImage(
                      imageUrl: "https://image.tmdb.org/t/p/w780$backdropPath",
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.black26),
                    )
                  : Container(color: theme.colorScheme.primaryContainer),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Tagline or Genres would go here
                  const SizedBox(height: 24),
                  Text("Overview", style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    overview ?? "No overview available.",
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton.icon(
            onPressed: context.watch<ImportService>().isImporting
                ? null
                : _startImportFlow,
            icon: const Icon(Icons.download_rounded),
            label: Text(
              context.watch<ImportService>().isImporting
                  ? "Importing..."
                  : "Choose File & Import",
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ),
      ),
    );
  }
}
