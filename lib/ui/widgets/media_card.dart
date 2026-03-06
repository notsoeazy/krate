import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:krate/core/constants.dart';
import 'package:krate/data/models/content.dart';

class MediaCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGhost = content.isGhost;

    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster Image
            AspectRatio(
              aspectRatio: 2 / 3,
              child: Stack(
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: _buildImage(context),
                  ),

                  // Ghost Badge / Missing File Overlay
                  if (isGhost)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.visibility_off_outlined,
                            color: Colors.white70,
                            size: 32,
                          ),
                        ),
                      ),
                    ),

                  // Series / Movie Indicator (optional)
                  if (showType)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          content.contentType == ContentType.series
                              ? 'TV'
                              : 'Movie',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Title - Fixed overflow issues with maxLines and ellipsis
            SizedBox(
              height: 36, // Reserve exactly two lines of text height
              child: Text(
                content.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  height: 1.2,
                  color: isGhost
                      ? theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.6,
                        )
                      : null,
                ),
              ),
            ),
            // Year / Genre
            if (content.releaseDate != null)
              Text(
                '${content.releaseDate!.year}',
                style: theme.textTheme.labelSmall,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    // 1. Local path exists?
    if (content.localPosterPath != null) {
      final file = File(content.localPosterPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      }
    }

    // 2. TMDB remote path fallback
    if (content.tmdbPosterPath != null) {
      return CachedNetworkImage(
        imageUrl: '$kTmdbImageBase/$kTmdbPosterSize${content.tmdbPosterPath}',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => _buildPlaceholder(context),
        errorWidget: (context, url, error) => _buildPlaceholder(context),
      );
    }

    // 3. Absolute fallback
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          content.contentType == ContentType.series
              ? Icons.tv
              : Icons.movie_outlined,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          size: 40,
        ),
      ),
    );
  }
}
