import 'package:flutter/material.dart';
import 'package:krate/models/app/content.dart';
import './media_poster_card.dart';

class MediaGrid extends StatelessWidget {
  final List<Content> items;
  final Function(Content)? onItemSelected;

  const MediaGrid({super.key, required this.items, this.onItemSelected});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.movie_filter_rounded,
              size: 64,
              color: Colors.white.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            Text(
              "No items in this category.",
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (context, index) {
        final content = items[index];
        return MediaPosterCard(
          content: content,
          onTap: () => onItemSelected?.call(content),
        );
      },
    );
  }
}
