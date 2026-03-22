import 'package:flutter/material.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/ui/screens/home/components/continue_watching_card.dart';

class ContinueWatchingRow extends StatelessWidget {
  final List<Content> items;
  final VoidCallback onSeeAll;

  const ContinueWatchingRow({
    super.key,
    required this.items,
    required this.onSeeAll,
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
              Text('Continue Watching', style: theme.textTheme.titleMedium),
              TextButton(onPressed: onSeeAll, child: const Text('See all')),
            ],
          ),
        ),
        // Horizontal media list
        SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) =>
                ContinueWatchingCard(content: items[index]),
          ),
        ),
      ],
    );
  }
}
