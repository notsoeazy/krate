import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/providers/providers.dart';

class MediaDetailsEpisodeTile extends ConsumerWidget {
  final int contentId;
  final Episode episode;
  final VoidCallback onPlay;
  final bool isCurrentlyPlaying;

  const MediaDetailsEpisodeTile({
    super.key,
    required this.contentId,
    required this.episode,
    required this.onPlay,
    this.isCurrentlyPlaying = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressAsync = ref.watch(watchProgressProvider(episode.id!));
    final selectionState = ref.watch(watchedSelectionProvider(contentId));
    final isSelected = selectionState.selectedEpisodeIds.contains(episode.id);

    if (selectionState.isSelectionMode) {
      return CheckboxListTile(
        value: isSelected,
        onChanged: (_) {
          if (episode.id != null) {
            ref
                .read(watchedSelectionProvider(contentId).notifier)
                .toggleSelection(episode.id!);
          }
        },
        title: _buildEpisodeInfo(context, progressAsync, theme),
        secondary: _buildEpisodeIndicator(context, progressAsync, theme),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );
    }

    return ExpansionTile(
      key: PageStorageKey('episode_${episode.id}'),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: const Border(),
      collapsedShape: const Border(),
      leading: _buildEpisodeIndicator(context, progressAsync, theme),
      title: _buildEpisodeInfo(context, progressAsync, theme),
      trailing: _buildPlayButton(context, theme),
      children: [_buildExpandedDetails(context, theme)],
    );
  }

  // Episode Indicator
  Widget _buildEpisodeIndicator(
    BuildContext context,
    AsyncValue<dynamic> progressAsync,
    ThemeData theme,
  ) {
    return progressAsync.when(
      data: (progress) {
        final percentage = progress?.percentage ?? 0.0;
        final isFinished = progress?.isFinished ?? false;

        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Progress Bar Overlay
              if (percentage > 0 || isFinished)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: isFinished ? 1.0 : percentage,
                    widthFactor: 1.0,
                    child: ColoredBox(
                      color: isFinished
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.primary.withValues(alpha: 0.55),
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
                        : (episode.hasFile
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
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
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

  // Title & Metadata
  Widget _buildEpisodeInfo(
    BuildContext context,
    AsyncValue<dynamic> progressAsync,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Episode Title
        Text(
          episode.title ?? 'Episode ${episode.episodeNumber}',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isCurrentlyPlaying ? FontWeight.bold : FontWeight.w600,
            color: episode.hasFile
                ? null
                : theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        // Episode Metadata (Runtime, Status)
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

            final parts = [runtimeStr, statusStr].where((s) => s.isNotEmpty);
            return Text(
              parts.join(' • '),
              style: theme.textTheme.labelSmall?.copyWith(
                color: episode.hasFile
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  // Play Button
  Widget _buildPlayButton(BuildContext context, ThemeData theme) {
    if (!episode.hasFile) {
      return Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Icon(
          Icons.cloud_off_outlined,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      );
    }

    return IconButton.filledTonal(
      icon: const Icon(Icons.play_arrow_rounded),
      onPressed: onPlay,
      tooltip: 'Play episode',
    );
  }

  // Expanded Details
  Widget _buildExpandedDetails(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          // Description
          Text(
            episode.description ?? 'No description available.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          // Air Date & File Path
          if (episode.airDate != null)
            _buildDetailRow(
              theme,
              Icons.calendar_today_outlined,
              'Aired: ${episode.airDate!.year}-'
              '${episode.airDate!.month.toString().padLeft(2, '0')}-'
              '${episode.airDate!.day.toString().padLeft(2, '0')}',
            ),
          if (episode.videoPath != null)
            _buildDetailRow(
              theme,
              Icons.file_present_outlined,
              episode.videoPath!.split('/').last,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
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
