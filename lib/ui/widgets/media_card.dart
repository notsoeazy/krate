import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/media_details/media_management_screen.dart';
import 'package:krate/ui/widgets/confirmation_dialog.dart';
import 'package:krate/ui/widgets/unavailable_overlay.dart';

class MediaCard extends ConsumerWidget {
  final Content content;
  final VoidCallback onTap;
  final double width;
  final bool showType;

  const MediaCard({
    super.key,
    required this.content,
    required this.onTap,
    this.width = 140,
    this.showType = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSeries = content.contentType == ContentType.series;

    // For series, watch the episode count so the progress badge is live
    final episodeCountAsync = isSeries && content.id != null
        ? ref.watch(contentEpisodeCountProvider(content.id!))
        : null;

    final isUnavailable = isSeries
        ? (episodeCountAsync?.valueOrNull?.available ?? 0) == 0 &&
              (episodeCountAsync?.valueOrNull?.total ?? 0) > 0
        : content.fileStatus == FileStatus.missing;

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showQuickActions(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            AspectRatio(
              aspectRatio: 2 / 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: UnavailableOverlay(
                        isUnavailable: isUnavailable,
                        borderRadius: 12,
                        child: _buildImage(context),
                      ),
                    ),
                  ),
                  // Favorite badge (top-left)
                  if (content.isFavorite)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _BadgeChip(
                        icon: Icons.favorite_rounded,
                        color: theme.colorScheme.error,
                        onColor: theme.colorScheme.onError,
                      ),
                    ),
                  // Content type abdge (top-riht)
                  if (showType)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _BadgeChip(
                        label: isSeries ? 'TV' : 'Movie',
                        color: theme.colorScheme.primaryContainer,
                        onColor: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),

                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: _buildStatusBadge(
                      context,
                      theme,
                      isSeries,
                      episodeCountAsync,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Title
            SizedBox(
              height: 36,
              child: Text(
                content.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(height: 1.2),
              ),
            ),

            // Metadata (Year, Runtime)
            Builder(
              builder: (context) {
                final parts = <String>[];
                if (content.releaseDate != null) {
                  parts.add('${content.releaseDate!.year}');
                }
                if (content.runtime != null && content.runtime! > 0) {
                  final isSeries = content.contentType == ContentType.series;
                  parts.add('${isSeries ? '~' : ''}${content.runtime}m');
                }

                if (parts.isEmpty) return const SizedBox.shrink();

                return Text(
                  parts.join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    ThemeData theme,
    bool isSeries,
    AsyncValue<({int total, int available})>? episodeCountAsync,
  ) {
    // Missing file (movie or series)
    if (content.fileStatus == FileStatus.missing) {
      return _BadgeChip(
        icon: Icons.block_outlined,
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.85,
        ),
        onColor: theme.colorScheme.onSurfaceVariant,
      );
    }

    // Series episode count badge
    if (isSeries && episodeCountAsync != null) {
      return episodeCountAsync.when(
        data: (counts) {
          if (counts.total == 0) return const SizedBox.shrink();
          final isCompleted = counts.available >= counts.total;
          return _BadgeChip(
            label: isCompleted ? '✓' : '${counts.available}/${counts.total}',
            color: isCompleted
                ? theme.colorScheme.tertiaryContainer
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.9,
                  ),
            onColor: isCompleted
                ? theme.colorScheme.onTertiaryContainer
                : theme.colorScheme.onSurfaceVariant,
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildImage(BuildContext context) {
    final theme = Theme.of(context);

    if (content.localPosterPath != null) {
      final file = File(content.localPosterPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          // Use updatedAt as a key to force rebuild when metadata changes (cache breaking)
          key: ValueKey(content.updatedAt),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } else {
        // If local path exists but file is missing, use placeholder (avoid network)
        return _buildPlaceholder(theme);
      }
    }

    if (content.tmdbPosterPath != null) {
      return CachedNetworkImage(
        imageUrl: '$kTmdbImageBase/$kTmdbPosterSize${content.tmdbPosterPath}',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => _buildPlaceholder(theme),
        errorWidget: (context, url, error) => _buildPlaceholder(theme),
      );
    }

    return _buildPlaceholder(theme);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          content.contentType == ContentType.series
              ? Icons.tv
              : Icons.movie_outlined,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          size: 40,
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final service = ref.read(watchProgressServiceProvider);
    final isSeries = content.contentType == ContentType.series;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  content.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              if (!isSeries)
                ListTile(
                  leading: const Icon(Icons.done_all_rounded),
                  title: const Text('Mark as watched'),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await ConfirmationDialog.show(
                      context,
                      title: 'Mark as watched?',
                      message:
                          'Mark "${content.title}" and all its episodes as watched?',
                    );
                    if (confirmed) {
                      await service.markSeasonFinished(content.id!, 0);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Marked "${content.title}" as watched',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('Clear watch history'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await ConfirmationDialog.show(
                    context,
                    title: 'Clear watch history?',
                    message:
                        'This will remove all watch progress for "${content.title}". This action cannot be undone.',
                    confirmLabel: 'Clear',
                    isDestructive: true,
                  );
                  if (confirmed) {
                    await service.clearSeriesProgress(content.id!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Cleared history for "${content.title}"',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  content.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  color: content.isFavorite ? theme.colorScheme.error : null,
                ),
                title: Text(
                  content.isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await ref
                      .read(contentRepoProvider)
                      .setFavorite(content.id!, !content.isFavorite);
                  ref.invalidate(contentProvider(content.id!));
                  _invalidateLibrary(ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('Manage media'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          MediaManagementScreen(contentId: content.id!),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _invalidateLibrary(WidgetRef ref) {
    ref.invalidate(moviesProvider);
    ref.invalidate(seriesProvider);
    ref.invalidate(recentMoviesProvider);
    ref.invalidate(recentSeriesProvider);
    ref.invalidate(continueWatchingProvider);
    ref.invalidate(watchingContentProvider);
    ref.invalidate(completedContentProvider);
  }
}

class _BadgeChip extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final Color color;
  final Color onColor;

  const _BadgeChip({
    this.label,
    this.icon,
    required this.color,
    required this.onColor,
  }) : assert(label != null || icon != null);

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: onColor,
      fontWeight: FontWeight.bold,
      fontSize: 10,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: icon != null
            ? Icon(icon, size: 11, color: onColor)
            : Text(label!, style: textStyle),
      ),
    );
  }
}
