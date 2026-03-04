import 'package:flutter/material.dart';

import 'media_card.dart';

class HorizontalMediaRow extends StatelessWidget {
  const HorizontalMediaRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: 10, // placeholder
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return const MediaCard();
        },
      ),
    );
  }
}
