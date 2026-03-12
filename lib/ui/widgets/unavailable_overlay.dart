import 'package:flutter/material.dart';

/// A reusable overlay that dims its content and shows an "Unavailable" indicator.
/// Commonly used over posters or cards when the media file is missing.
class UnavailableOverlay extends StatelessWidget {
  final bool isUnavailable;
  final Widget? child;
  final double borderRadius;
  final String label;

  const UnavailableOverlay({
    super.key,
    required this.isUnavailable,
    this.child,
    this.borderRadius = 12,
    this.label = 'Unavailable',
  });

  @override
  Widget build(BuildContext context) {
    if (!isUnavailable) return child ?? const SizedBox.shrink();

    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.passthrough,
      children: [
        if (child != null) child!,
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.scrim.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block_outlined,
                  color: theme.colorScheme.error,
                  size: 32,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
