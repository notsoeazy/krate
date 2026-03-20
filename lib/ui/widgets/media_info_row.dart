import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/utils/constants.dart';

class MediaInfoRow extends StatelessWidget {
  final Content content;
  final bool useOnBackdrop;
  final ContentType? typeOverride;

  const MediaInfoRow({
    super.key,
    required this.content,
    this.useOnBackdrop = false,
    this.typeOverride,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTextStyle = useOnBackdrop
        ? theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 8,
                color: Colors.black54,
              ),
            ],
          )
        : theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          );

    final metadataStyle = useOnBackdrop
        ? theme.textTheme.bodySmall?.copyWith(color: Colors.white70)
        : theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildPoster(context),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                content.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: baseTextStyle,
              ),
              const SizedBox(height: 8),
              _buildMetadataRow(context, metadataStyle),
              if (content.voteAverage > 0) ...[
                const SizedBox(height: 8),
                _buildRatingRow(context, metadataStyle),
              ],
              if (useOnBackdrop &&
                  content.tagline != null &&
                  content.tagline!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  content.tagline!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPoster(BuildContext context) {
    ImageProvider? image;

    // Priority: Local Poster
    if (content.localPosterPath != null) {
      final f = File(content.localPosterPath!);
      if (f.existsSync()) {
        image = FileImage(f);
      }
    }

    // Fallback: TMDB Poster (Network)
    if (image == null && content.tmdbPosterPath != null) {
      image = CachedNetworkImageProvider(
        '$kTmdbImageBase/w342${content.tmdbPosterPath}',
      );
    }

    return Container(
      width: 110,
      height: 165,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: useOnBackdrop
            ? const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: image != null
            ? Image(
                key: ValueKey('${content.id}_${content.updatedAt}'),
                image: image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: Icon(
        content.contentType == ContentType.series ? Icons.tv : Icons.movie,
        color: Colors.white24,
        size: 40,
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context, TextStyle? style) {
    final parts = <String>[];
    if (content.releaseDate != null) {
      parts.add('${content.releaseDate!.year}');
    }

    final contentType = typeOverride ?? content.contentType;
    if (contentType == ContentType.series) {
      if (content.totalSeasons > 0) {
        parts.add(
          '${content.totalSeasons} ${content.totalSeasons == 1 ? 'Season' : 'Seasons'}',
        );
      }
    } else {
      if (content.runtime != null) {
        parts.add('${content.runtime} min');
      }
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (int i = 0; i < parts.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('•', style: style),
            ),
          Text(parts[i], style: style),
        ],
      ],
    );
  }

  Widget _buildRatingRow(BuildContext context, TextStyle? style) {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 4),
        Text(
          content.voteAverage.toStringAsFixed(1),
          style: style?.copyWith(
            fontWeight: FontWeight.bold,
            color: useOnBackdrop ? Colors.white : null,
          ),
        ),
        Text(
          ' / 10',
          style: style?.copyWith(
            fontSize: 12,
            color: useOnBackdrop ? Colors.white70 : null,
          ),
        ),
      ],
    );
  }
}
