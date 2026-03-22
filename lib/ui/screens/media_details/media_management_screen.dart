import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/busy_overlay.dart';
import 'package:krate/ui/screens/media_details/components/media_management_movie_list.dart';
import 'package:krate/ui/screens/media_details/components/media_management_series_list.dart';
import 'package:krate/ui/screens/media_details/components/media_management_bottom_bar.dart';
import 'package:krate/ui/widgets/confirmation_dialog.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/utils/errors.dart';
import 'package:krate/utils/feedback_utils.dart';

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

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Media Files',
      message: 'Delete media files for ${toDelete.length} episode(s)?\n'
          'This removes the files from storage but keeps the episode in your library.',
      confirmLabel: 'Delete',
      isDestructive: true,
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

      bool tmdbFailed = false;
      bool isOffline = false;
      // Combined Sync: Try TMDB Fetch first
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
        debugPrint('[MediaManagementScreen] Metadata fetch error: $e');
        if (e is NoInternetException) {
          isOffline = true;
        }
        tmdbFailed = true;
      }

      // Vault Sync (targeted)
      if (content.podPath != null) {
        await ref
            .read(vaultSyncProvider.notifier)
            .syncPod(content.podPath!, content.id!);
      }

      if (mounted) {
        if (isOffline) {
          FeedbackUtils.showInfoSnackBar(context, 'Vault synced, but no internet connection to TMDB.');
        } else if (tmdbFailed) {
          FeedbackUtils.showInfoSnackBar(context, 'Vault synced, but TMDB fetch failed.');
        } else {
          FeedbackUtils.showSuccessSnackBar(context, 'Sync complete');
        }
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
          appBar: _MediaManagementAppBar(
            title: content.title,
            isSeries: isSeries,
            state: s,
            onSync: () => _runSync(content),
            onEnterDelete: _notifier.enterDeleteMode,
            onExitDelete: _notifier.exitDeleteMode,
          ),
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
          bottomNavigationBar: episodesAsync
              .whenData(
                (eps) => MediaManagementBottomBar(
                  state: s,
                  content: content,
                  episodes: eps,
                  onImport: () => _runImport(content),
                  onDelete: () => _runDelete(content, eps),
                ),
              )
              .value,
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _MediaManagementAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isSeries;
  final MediaManagementState state;
  final VoidCallback onSync;
  final VoidCallback onEnterDelete;
  final VoidCallback onExitDelete;

  const _MediaManagementAppBar({
    required this.title,
    required this.isSeries,
    required this.state,
    required this.onSync,
    required this.onEnterDelete,
    required this.onExitDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('Manage $title'),
      actions: [
        if (isSeries && !state.isDeleteMode)
          IconButton(
            icon: const Icon(Icons.sync_outlined),
            tooltip: 'Rescan from TMDB',
            onPressed: state.canScan ? onSync : null,
          ),
        if (!state.isDeleteMode)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete episodes',
            onPressed: state.canSwitchToDelete ? onEnterDelete : null,
          )
        else
          TextButton(
            onPressed: state.hasJobRunning ? null : onExitDelete,
            child: const Text('Cancel'),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
