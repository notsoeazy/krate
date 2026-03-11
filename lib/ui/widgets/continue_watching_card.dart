import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/library/media_details_screen.dart';
import 'package:krate/ui/screens/player/player_screen.dart';
import 'package:krate/utils/constants.dart';

class ContinueWatchingCard extends ConsumerWidget {
  final Content content;

  const ContinueWatchingCard({super.key, required this.content});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resumeEpisodeAsync = ref.watch(resumeEpisodeProvider(content.id!));
    final isLoading = resumeEpisodeAsync.isLoading;
    final episode = resumeEpisodeAsync.valueOrNull;

    final watchProgressAsync = episode != null
        ? ref.watch(watchProgressProvider(episode.id!))
        : null;
    final progress = watchProgressAsync?.valueOrNull;

    Widget imageWidget;
    if (content.localBackdropPath != null &&
        File(content.localBackdropPath!).existsSync()) {
      imageWidget = Image.file(
        File(content.localBackdropPath!),
        key: ValueKey('backdrop_${content.updatedAt}'),
        fit: BoxFit.cover,
      );
    } else if (content.tmdbBackdropPath != null) {
      imageWidget = CachedNetworkImage(
        imageUrl: '$kTmdbImageBase/$kTmdbBackdropSize${content.tmdbBackdropPath}',
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(theme),
        errorWidget: (context, url, error) => _buildPlaceholder(theme),
      );
    } else if (content.localPosterPath != null &&
        File(content.localPosterPath!).existsSync()) {
      imageWidget = Image.file(
        File(content.localPosterPath!),
        key: ValueKey('poster_${content.updatedAt}'),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    } else if (content.tmdbPosterPath != null) {
      imageWidget = CachedNetworkImage(
        imageUrl: '$kTmdbImageBase/$kTmdbPosterSize${content.tmdbPosterPath}',
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        placeholder: (context, url) => _buildPlaceholder(theme),
        errorWidget: (context, url, error) => _buildPlaceholder(theme),
      );
    } else {
      imageWidget = _buildPlaceholder(theme);
    }

    String? minsLeftText;
    if (progress != null && progress.durationMs > 0) {
      final remainingMs = progress.durationMs - progress.positionMs;
      final remainingMins = (remainingMs / 60000).ceil();
      if (remainingMins > 0) {
        minsLeftText = '$remainingMins min left';
      }
    }

    return SizedBox(
      width: 260,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (episode == null || !episode.hasFile) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MediaDetailsScreen(contentId: content.id!),
                ),
              );
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PlayerScreen(episodeId: episode.id!),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageWidget,

              // Dark gradient scrim from bottom for text readability
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        theme.colorScheme.surface.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Title and Info Row
              Positioned(
                left: 12,
                bottom: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      content.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        (() {
                          final season = episode?.seasonNumber;
                          final epNum = episode?.episodeNumber;
                          if (season != null && epNum != null) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'S$season E$epNum',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (minsLeftText != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '•',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        })(),
                        if (minsLeftText != null) ...[
                          Expanded(
                            child: Text(
                              minsLeftText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Play / Loading Button centered
              Positioned.fill(
                child: Center(
                  child: isLoading
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.scrim.withValues(alpha: 0.38),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: theme.colorScheme.onPrimary,
                              size: 28,
                            ),
                          ),
                        ),
                ),
              ),

              // Progress Bar at the very bottom
              if (progress != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: progress.percentage,
                    backgroundColor: Colors.transparent,
                    color: theme.colorScheme.primary,
                    minHeight: 3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
