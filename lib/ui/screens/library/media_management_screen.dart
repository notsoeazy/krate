import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/busy_overlay.dart';
import 'package:krate/ui/widgets/media_management_bottom_bar.dart';
import 'package:krate/ui/widgets/media_management_movie_list.dart';
import 'package:krate/ui/widgets/media_management_series_list.dart';
import 'package:krate/utils/constants.dart';

class MediaManagementScreen extends ConsumerStatefulWidget {
  final int contentId;
  const MediaManagementScreen({super.key, required this.contentId});

  @override
  ConsumerState<MediaManagementScreen> createState() =>
      _MediaManagementScreenState();
}

class _MediaManagementScreenState extends ConsumerState<MediaManagementScreen> {
  MediaManagementNotifier get _notifier =>
      ref.read(mediaManagementProvider(widget.contentId).notifier);

  // Operations

  Future<void> _runImport(Content content) async {
    final s = ref.read(mediaManagementProvider(widget.contentId));
    if (!s.importButtonEnabled) return;

    final files = Map<int, String>.fromEntries(
      s.stagedFiles.values
          .where((f) => f.path != null)
          .map((f) => MapEntry(f.episodeId, f.path!)),
    );

    final subtitlePaths = Map<int, List<String>>.fromEntries(
      s.stagedFiles.values.map((f) => MapEntry(f.episodeId, f.subtitlePaths)),
    );

    _notifier.markJobRunning();
    if (mounted) Navigator.of(context).pop();

    ref
        .read(importJobsProvider.notifier)
        .linkEpisodes(
          service: ref.read(importServiceProvider),
          content: content,
          episodeFiles: files,
          episodeSubtitles: subtitlePaths,
        );
  }

  Future<void> _runDelete(Content content, List<Episode> allEpisodes) async {
    final s = ref.read(mediaManagementProvider(widget.contentId));
    if (!s.deleteButtonEnabled) return;

    final toDelete = allEpisodes
        .where((e) => s.deleteSelections.contains(e.id))
        .toList();
    if (toDelete.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Delete Media Files'),
        content: Text(
          'Delete media files for ${toDelete.length} episode(s)?\n'
          'This removes the files from storage but keeps the episode in your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _notifier.markJobRunning();
    try {
      await ref
          .read(importJobsProvider.notifier)
          .deleteEpisodes(
            service: ref.read(importServiceProvider),
            content: content,
            episodes: toDelete,
          );
    } finally {
      if (mounted) _notifier.markJobDone();
    }
  }

  Future<void> _runSync(Content content) async {
    final s = ref.read(mediaManagementProvider(widget.contentId));
    if (!s.canScan) return;

    _notifier.markJobRunning();
    try {
      final isSeries = content.contentType == ContentType.series;
      final importJobs = ref.read(importJobsProvider.notifier);
      final importService = ref.read(importServiceProvider);

      // 1. Combined Sync: Try TMDB Fetch first
      try {
        if (isSeries) {
          await importJobs.fetchMetadataSeries(
            service: importService,
            content: content,
          );
        } else {
          await importJobs.fetchMetadataMovie(
            service: importService,
            content: content,
          );
        }
      } catch (e) {
        debugPrint('[MediaManagement] Metadata fetch failed (likely offline): $e');
        // If offline, we just continue to Vault Sync
      }

      // 2. Vault Sync (targeted)
      if (content.podPath != null) {
        await ref
            .read(vaultSyncProvider.notifier)
            .syncPod(content.podPath!, content.id!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync complete')),
        );
      }
    } finally {
      if (mounted) _notifier.markJobDone();
    }
  }



  @override
  Widget build(BuildContext context) {
    final s = ref.watch(mediaManagementProvider(widget.contentId));
    final contentAsync = ref.watch(contentProvider(widget.contentId));
    final episodesAsync = ref.watch(contentEpisodesProvider(widget.contentId));
    return contentAsync.when(
      data: (content) {
        if (content == null) {
          return const Scaffold(body: Center(child: Text('Content not found')));
        }

        final isSeries = content.contentType == ContentType.series;

        return Scaffold(
          appBar: AppBar(
            title: Text('Manage ${content.title}'),
            // Toolbar Actions
            actions: [
              if (isSeries && !s.isDeleteMode)
                IconButton(
                  icon: const Icon(Icons.sync_outlined),
                  tooltip: 'Rescan from TMDB',
                  onPressed: s.canScan ? () => _runSync(content) : null,
                ),
              if (!s.isDeleteMode)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete episodes',
                  onPressed: s.canSwitchToDelete
                      ? _notifier.enterDeleteMode
                      : null,
                )
              else
                TextButton(
                  onPressed: s.hasJobRunning ? null : _notifier.exitDeleteMode,
                  child: const Text('Cancel'),
                ),
            ],
          ),
          // Content Stack
          body: Stack(
            children: [
              // Episode Selection List
              episodesAsync.when(
                data: (episodes) {
                  if (content.contentType == ContentType.movie) {
                    final movieEp = episodes.firstWhere(
                      (e) => e.isMovie,
                      orElse: () => episodes.first,
                    );
                    return MediaManagementMovieList(
                      movieEp: movieEp,
                      state: s,
                      notifier: _notifier,
                    );
                  }

                  // Series: group by season
                  return MediaManagementSeriesList(
                    episodes: episodes,
                    state: s,
                    notifier: _notifier,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
              // Overlays
              if (s.hasJobRunning) const BusyOverlay(message: 'Processing…'),
              if (s.isPickerOpen)
                const BusyOverlay(message: 'Accessing storage…'),
            ],
          ),
          // Bottom Action Bar
          bottomNavigationBar: episodesAsync
              .whenData((eps) => MediaManagementBottomBar(
                    state: s,
                    content: content,
                    episodes: eps,
                    onImport: () => _runImport(content),
                    onDelete: () => _runDelete(content, eps),
                  ))
              .value,
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
