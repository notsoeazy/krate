import 'package:flutter/material.dart';
import 'package:krate/models/app/content.dart';
import 'media_card.dart';
import 'section_title.dart';

class HorizontalMediaRow extends StatelessWidget {
  final String title;
  final List<Content> items;
  final Map<int, double>? progresses; // contentId -> progress percentage
  final Function(Content)? onItemSelected;

  const HorizontalMediaRow({
    super.key,
    required this.title,
    required this.items,
    this.progresses,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: title),
        SizedBox(
          height: 240, // Adjusted for card + text
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final content = items[index];
              return MediaCard(
                content: content,
                progress: progresses?[content.id],
                onTap: () => onItemSelected?.call(content),
              );
            },
          ),
        ),
      ],
    );
  }
}
