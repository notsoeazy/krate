import 'package:flutter/material.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/ui/widgets/media_card.dart';

/// A horizontal scrolling row of [MediaCard]s with a titled header and
/// a "See all" action button.
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
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              // TextButton is the correct M3 low-emphasis action ─ replaces
              // the old InkWell-wrapped Text.
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
        ),
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
