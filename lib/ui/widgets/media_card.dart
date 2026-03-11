import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/providers/providers.dart';

/// Poster card used in grid and horizontal row views.
///
/// Replaces the ghost overlay with an M3-style badge system:
/// - ❤ Favorite badge (top-left)
/// - The poster always shows; file-status and progress shown as overlay badges
/// - Series: episode count badge (e.g. "3/12") bottom-right
/// - No-file badge shows a small icon for missing content (not a full overlay)
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

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Poster + badges ────────────────────────────────────────
            AspectRatio(
              aspectRatio: 2 / 3,
              child: Stack(
                children: [
                  // Poster card
                  Positioned.fill(
                    child: Card(
                      margin: EdgeInsets.zero,
                      clipBehavior: Clip.antiAlias,
                      child: _buildImage(context),
                    ),
                  ),

                  // ── Top-left: Favorite badge ───────────────────────
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

                  // ── Top-right: Type badge ──────────────────────────
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

                  // ── Bottom-right: Status badge ─────────────────────
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

            // ── Title ──────────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: Text(
                content.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(height: 1.2),
              ),
            ),

            // ── Metadata (Year • Runtime) ─────────────────────────────
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
    // Missing file (movie)
    if (!isSeries && content.fileStatus == FileStatus.missing) {
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
}

// ── Badge chip helper ─────────────────────────────────────────────────────────

/// Small pill/icon badge used as poster overlay.
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
