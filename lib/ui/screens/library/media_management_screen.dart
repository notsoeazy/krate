import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/busy_overlay.dart';
import 'package:krate/ui/widgets/managed_episode_tile.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/utils/errors.dart';

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

  // -------------------------------------------------------------------------
  // Operations
  // -------------------------------------------------------------------------

  Future<void> _runImport(Content content) async {
    final s = ref.read(mediaManagementProvider(widget.contentId));
    if (!s.importButtonEnabled) return;

    final files = Map<int, String>.fromEntries(
      s.stagedFiles.values.map((f) => MapEntry(f.episodeId, f.path)),
    );

    _notifier.markJobRunning();

    // Pop immediately — job runs in background via ImportJobsNotifier
    if (mounted) Navigator.of(context).pop();

    ref
        .read(importJobsProvider.notifier)
        .linkEpisodes(
          service: ref.read(importServiceProvider),
          content: content,
          episodeFiles: files,
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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
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

  Future<void> _runRescan(Content content) async {
    final s = ref.read(mediaManagementProvider(widget.contentId));
    if (!s.canScan) return;

    _notifier.markJobRunning();
    try {
      await ref
          .read(importJobsProvider.notifier)
          .rescanSeries(
            service: ref.read(importServiceProvider),
            content: content,
          );
      ref.invalidate(contentEpisodesProvider(widget.contentId));
      ref.invalidate(contentProvider(widget.contentId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Series rescanned from TMDB')),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e is NoInternetException ? e.message : 'Rescan failed: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) _notifier.markJobDone();
    }
  }

  // -------------------------------------------------------------------------
  // Build Components
  // -------------------------------------------------------------------------

  Widget _buildBottomBar(
    MediaManagementState s,
    Content content,
    List<Episode> episodes,
  ) {
    if (!s.importButtonEnabled && !s.deleteButtonEnabled) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            if (s.importButtonEnabled)
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _runImport(content),
                  icon: const Icon(Icons.link),
                  label: Text(
                    'Import ${s.stagedFiles.length} File${s.stagedFiles.length == 1 ? '' : 's'}',
                  ),
                ),
              ),
            if (s.deleteButtonEnabled) ...[
              if (s.importButtonEnabled) const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _runDelete(content, episodes),
                  icon: const Icon(Icons.delete_outline),
                  label: Text('Delete ${s.deleteSelections.length}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
            actions: [
              if (isSeries && !s.isDeleteMode)
                IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Rescan from TMDB',
                  onPressed: s.canScan ? () => _runRescan(content) : null,
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
          body: Stack(
            children: [
              episodesAsync.when(
                data: (episodes) {
                  if (content.contentType == ContentType.movie) {
                    final movieEp = episodes.firstWhere(
                      (e) => e.isMovie,
                      orElse: () => episodes.first,
                    );
                    return ListView(
                      children: [
                        ManagedEpisodeTile(
                          episode: movieEp,
                          mode: s.isDeleteMode
                              ? ManagedTileMode.delete
                              : ManagedTileMode.normal,
                          isSelected: s.deleteSelections.contains(movieEp.id),
                          onSelectedChanged: (val) =>
                              _notifier.toggleDeleteSelection(
                                movieEp.id!,
                                selected: val == true,
                              ),
                          stagedFile: s.stagedFiles[movieEp.id],
                          onImport: () => _notifier.pickFile(
                            episodeId: movieEp.id!,
                            episodeHasFile: movieEp.hasFile,
                          ),
                          onRemoveFile: () =>
                              _notifier.removeStaged(movieEp.id!),
                        ),
                      ],
                    );
                  }

                  // --- Series: group by season ---
                  final seasons = <int, List<Episode>>{};
                  for (final ep in episodes) {
                    final sNum = ep.seasonNumber ?? 0;
                    seasons.putIfAbsent(sNum, () => []).add(ep);
                  }
                  final sortedSeasons = seasons.keys.toList()..sort();

                  return ListView.builder(
                    itemCount: sortedSeasons.length,
                    itemBuilder: (context, index) {
                      final seasonNum = sortedSeasons[index];
                      final seasonEpisodes = seasons[seasonNum]!
                        ..sort(
                          (a, b) => (a.episodeNumber ?? 0).compareTo(
                            b.episodeNumber ?? 0,
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
                          subtitle: Text(
                            '${seasonEpisodes.where((e) => e.hasFile).length} / ${seasonEpisodes.length} Episodes',
                          ),
                          initiallyExpanded: index == 0,
                          children: seasonEpisodes
                              .map(
                                (ep) => ManagedEpisodeTile(
                                  episode: ep,
                                  mode: s.isDeleteMode
                                      ? ManagedTileMode.delete
                                      : ManagedTileMode.normal,
                                  isSelected: s.deleteSelections.contains(
                                    ep.id,
                                  ),
                                  onSelectedChanged: (val) =>
                                      _notifier.toggleDeleteSelection(
                                        ep.id!,
                                        selected: val == true,
                                      ),
                                  stagedFile: s.stagedFiles[ep.id],
                                  onImport: () => _notifier.pickFile(
                                    episodeId: ep.id!,
                                    episodeHasFile: ep.hasFile,
                                  ),
                                  onRemoveFile: () =>
                                      _notifier.removeStaged(ep.id!),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
              if (s.hasJobRunning) const BusyOverlay(message: 'Processing...'),
              if (s.isPickerOpen)
                const BusyOverlay(message: 'Accessing storage...'),
            ],
          ),
          bottomNavigationBar: episodesAsync
              .whenData((episodes) => _buildBottomBar(s, content, episodes))
              .value,
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
