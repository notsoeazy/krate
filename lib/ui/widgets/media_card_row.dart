import 'package:flutter/material.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/ui/widgets/media_card.dart';

class MediaCardRow extends StatelessWidget {
  final String title;
  final List<Content> items;
  final VoidCallback onSeeAll;
  final Function(Content) onItemSelected;

  const MediaCardRow({
    super.key,
    required this.title,
    required this.items,
    required this.onSeeAll,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
        ),
        // Horizontal media list
        SizedBox(
          height: 240,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return MediaCard(
                content: items[index],
                onTap: () => onItemSelected(items[index]),
                width: 120,
              );
            },
          ),
        ),
      ],
    );
  }
}
