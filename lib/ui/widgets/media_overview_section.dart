import 'package:flutter/material.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/ui/widgets/expandable_text.dart';

class MediaOverviewSection extends StatelessWidget {
  final Content content;

  const MediaOverviewSection({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description:',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ExpandableText(
          text: content.description ?? 'No description available.',
          style: theme.textTheme.bodyMedium,
        ),
        if (content.genres != null && content.genres!.isNotEmpty) ...[
          const SizedBox(height: 20),
          _GenreChips(genres: content.genres!),
        ],
      ],
    );
  }
}

class _GenreChips extends StatelessWidget {
  final List<String> genres;

  const _GenreChips({required this.genres});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: genres.map((genre) {
        return Chip(
          label: Text(genre),
          labelStyle: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
          backgroundColor: theme.colorScheme.secondaryContainer,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }
}
