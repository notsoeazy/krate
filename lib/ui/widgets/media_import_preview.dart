import 'package:flutter/material.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/utils/constants.dart';

class MediaImportPreview extends StatelessWidget {
  final Content content;
  final ContentType type;

  const MediaImportPreview({
    super.key,
    required this.content,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.tmdbPosterPath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              '$kTmdbImageBase/w185${content.tmdbPosterPath}',
              width: 110,
            ),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content.title,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (content.releaseDate != null)
                Text(
                  '${content.releaseDate!.year} • '
                  '${type.name.toUpperCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                content.description ?? '',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
