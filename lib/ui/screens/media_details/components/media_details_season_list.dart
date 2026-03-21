import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/player/player_screen.dart';
import 'package:krate/ui/screens/media_details/components/media_details_episode_tile.dart';

class MediaDetailsSeasonList extends ConsumerWidget {
  final int contentId;
  final int seasonNumber;

  const MediaDetailsSeasonList({
    super.key,
    required this.contentId,
    required this.seasonNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final episodesAsync = ref.watch(
      mergedEpisodesProvider((
        contentId: contentId,
        seasonNumber: seasonNumber,
      )),
    );

    return episodesAsync.when(
      data: (eps) {
        if (eps.isEmpty) {
          return Center(
            child: Text(
              'No episodes found for this season.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          );
        }
        return ListView.separated(
          key: PageStorageKey('season_$seasonNumber'),
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
          itemCount: eps.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, index) {
            final ep = eps[index];
            return MediaDetailsEpisodeTile(
              contentId: contentId,
              episode: ep,
              onPlay: () {
                if (ep.id != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PlayerScreen(episodeId: ep.id!),
                    ),
                  );
                }
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading episodes: $e')),
    );
  }
}
