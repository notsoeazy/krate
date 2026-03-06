import 'dart:io';
import 'package:flutter/material.dart';
import 'package:krate/models/app/content.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MediaCard extends StatelessWidget {
  final Content content;
  final double? progress;
  final VoidCallback? onTap;

  const MediaCard({
    super.key,
    required this.content,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 130, // Fixed width for horizontal lists
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
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
                            size: 14,
                          ),
                        ),
                      ),
                    if (progress != null && progress! > 0)
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          height: 3,
                          width: double.infinity,
                          color: Colors.white24,
                          child: FractionallySizedBox(
                            alignment: Alignment.bottomLeft,
                            widthFactor: progress!.clamp(0.0, 1.0),
                            child: Container(color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    content.releaseDate?.year.toString() ??
                        content.contentType.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
      );
    }
    return Container(color: Colors.white10);
  }
}
