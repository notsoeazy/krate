import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/providers/providers.dart';

class EpisodeTile extends ConsumerWidget {
  final Episode episode;
  final VoidCallback onPlay;
  final bool isCurrentlyPlaying;

  const EpisodeTile({
    super.key,
    required this.episode,
    required this.onPlay,
    this.isCurrentlyPlaying = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressAsync = ref.watch(watchProgressProvider(episode.id!));

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildEpisodeIndicator(context, ref, progressAsync),
        title: _buildEpisodeInfo(context, progressAsync),
        trailing: _buildPlayButton(context),
        children: [_buildExpandedDetails(context)],
      ),
    );
  }

  Widget _buildEpisodeIndicator(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> progressAsync,
  ) {
    final theme = Theme.of(context);
    final hasFile = episode.hasFile;

    return progressAsync.when(
      data: (progress) {
        final percentage = (progress != null) ? progress.percentage : 0.0;
        final isFinished = (progress != null) ? progress.isFinished : false;

        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Progress Fill
              if (percentage > 0)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: percentage,
                    widthFactor: 1.0,
                    child: Container(
                      color: isFinished
                          ? theme.colorScheme.primary.withValues(alpha: 0.3)
                          : theme.colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              // Episode Number
              Center(
                child: Text(
                  '${episode.episodeNumber ?? ''}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isFinished
                        ? theme.colorScheme.primary
                        : (hasFile
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.3,
                                )),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox(width: 44, height: 44),
    );
  }

  Widget _buildEpisodeInfo(
    BuildContext context,
    AsyncValue<dynamic> progressAsync,
  ) {
    final theme = Theme.of(context);
    final hasFile = episode.hasFile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          episode.title ?? 'Episode ${episode.episodeNumber}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isCurrentlyPlaying ? FontWeight.bold : FontWeight.w600,
            color: hasFile
                ? null
                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        progressAsync.when(
          data: (progress) {
            final runtimeStr = episode.runtime != null
                ? '${episode.runtime} min'
                : '';
            String statusStr = '';

            if (progress != null) {
              if (progress.isFinished) {
                statusStr = 'Watched';
              } else if (progress.positionMs > 0) {
                final remainingMs = progress.durationMs - progress.positionMs;
                final remainingMin = (remainingMs / 60000).ceil();
                statusStr = '${remainingMin}m left';
              }
            }

            return Text(
              [runtimeStr, statusStr].where((s) => s.isNotEmpty).join(' • '),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    final theme = Theme.of(context);
    if (!episode.hasFile) {
      return Icon(
        Icons.cloud_off_outlined,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
      );
    }

    return IconButton(
      icon: const Icon(Icons.play_circle_filled, size: 28),
      color: theme.colorScheme.primary,
      onPressed: onPlay,
    );
  }

  Widget _buildExpandedDetails(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            episode.description ?? 'No description available.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (episode.airDate != null)
            _buildDetailRow(
              context,
              Icons.calendar_today_outlined,
              'Aired: ${episode.airDate!.year}-${episode.airDate!.month.toString().padLeft(2, '0')}-${episode.airDate!.day.toString().padLeft(2, '0')}',
            ),
          if (episode.videoPath != null)
            _buildDetailRow(
              context,
              Icons.file_present_outlined,
              episode.videoPath!.split('/').last,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
