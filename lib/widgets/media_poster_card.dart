import 'package:flutter/material.dart';

class MediaPosterCard extends StatelessWidget {
  const MediaPosterCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: colorScheme.surfaceContainerHigh,
                  child: const Icon(Icons.movie, size: 50),
                ),

                // Progress bar (bottom)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    height: 4,
                    width: 60,
                    color: colorScheme.primary,
                  ),
                ),

                // Top right check badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: colorScheme.primary,
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Interstellar",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          "2h 49m",
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
      ],
    );
  }
}
