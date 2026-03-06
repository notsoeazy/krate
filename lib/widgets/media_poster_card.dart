import 'dart:io';
import 'package:flutter/material.dart';
import 'package:krate/models/app/content.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MediaPosterCard extends StatelessWidget {
  final Content content;
  final double? progress; // 0.0 to 1.0 (for continue watching)
  final VoidCallback? onTap;

  const MediaPosterCard({
    super.key,
    required this.content,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Poster Image (Local or Remote)
                  _buildPoster(),

                  if (!content.hasFile)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: const Icon(
                          Icons.cloud_off_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ),

                  // Progress bar (bottom)
                  if (progress != null && progress! > 0)
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        height: 4,
                        width: double.infinity,
                        color: Colors.white24,
                        child: FractionallySizedBox(
                          alignment: Alignment.bottomLeft,
                          widthFactor: progress!.clamp(0.0, 1.0),
                          child: Container(color: colorScheme.primary),
                        ),
                      ),
                    ),

                  // Favorite Indicator (Optional overlay)
                  if (content.isFavorite)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red[400],
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _getSubtitle(),
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPoster() {
    if (content.localPosterPath != null &&
        File(content.localPosterPath!).existsSync()) {
      return Image.file(File(content.localPosterPath!), fit: BoxFit.cover);
    }

    if (content.posterPath != null) {
      return CachedNetworkImage(
        imageUrl: "https://image.tmdb.org/t/p/w342${content.posterPath}",
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.white10),
        errorWidget: (context, url, error) => const Icon(Icons.broken_image),
      );
    }

    return Container(
      color: Colors.white10,
      child: Icon(
        Icons.movie_filter_rounded,
        size: 40,
        color: Colors.white.withOpacity(0.1),
      ),
    );
  }

  String _getSubtitle() {
    final year = content.releaseDate?.year.toString() ?? "";
    final type = content.contentType.name.toUpperCase();
    if (year.isNotEmpty) return "$year • $type";
    return type;
  }
}
