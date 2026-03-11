import 'dart:ui';
import 'package:flutter/material.dart';

// Full-screen busy overlay used during blocking async operations.
class BusyOverlay extends StatelessWidget {
  final String message;
  final bool showBlur;

  const BusyOverlay({
    super.key,
    this.message = 'Loading...',
    this.showBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = ColoredBox(
      color: theme.colorScheme.scrim.withValues(alpha: 0.54),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );

    if (showBlur) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: content,
      );
    }

    return content;
  }
}
