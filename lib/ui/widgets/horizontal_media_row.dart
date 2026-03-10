import 'package:flutter/material.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/ui/widgets/media_card.dart';

class HorizontalMediaRow extends StatelessWidget {
  final String title;
  final List<Content> items;
  final VoidCallback onSeeAll;
  final Function(Content) onItemSelected;

  const HorizontalMediaRow({
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              InkWell(
                onTap: onSeeAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    'See all →',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
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
