import 'package:flutter/material.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/media_details/components/media_management_episode_tile.dart';

class MediaManagementSeriesList extends StatelessWidget {
  final List<Episode> episodes;
  final MediaManagementState state;
  final MediaManagementNotifier notifier;

  const MediaManagementSeriesList({
    super.key,
    required this.episodes,
    required this.state,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seasons = <int, List<Episode>>{};
    for (final ep in episodes) {
      seasons.putIfAbsent(ep.seasonNumber ?? 0, () => []).add(ep);
    }
    final sortedSeasons = seasons.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedSeasons.length,
      itemBuilder: (context, index) {
        final seasonNum = sortedSeasons[index];
        final seasonEpisodes = seasons[seasonNum]!
          ..sort(
            (a, b) => (a.episodeNumber ?? 0).compareTo(b.episodeNumber ?? 0),
          );

        return ExpansionTile(
          title: Text(
            'Season $seasonNum',
            style: theme.textTheme.titleMedium,
          ),
          subtitle: Text(
            '${seasonEpisodes.where((e) => e.hasFile).length}'
            ' / ${seasonEpisodes.length} Episodes',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          shape: const Border(),
          collapsedShape: const Border(),
          initiallyExpanded: index == 0,
          children: seasonEpisodes.map((ep) {
            return MediaManagementEpisodeTile(
              episode: ep,
              mode: state.isDeleteMode
                  ? ManagedTileMode.delete
                  : ManagedTileMode.normal,
              isSelected: state.deleteSelections.contains(ep.id),
              onSelectedChanged: (val) => notifier.toggleDeleteSelection(
                ep.id!,
                selected: val == true,
              ),
              stagedFile: state.stagedFiles[ep.id],
              onImport: () => notifier.pickMediaWithSubtitles(
                episodeId: ep.id!,
                episodeHasFile: ep.hasFile,
                onError: (err) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err)),
                ),
              ),
              onAddSubtitles: () => notifier.pickSubtitles(
                episodeId: ep.id!,
                existingVideoPath: ep.videoPath,
                onError: (err) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(err)),
                ),
              ),
              onRemoveFile: () => notifier.removeStaged(ep.id!),
            );
          }).toList(),
        );
      },
    );
  }
}
