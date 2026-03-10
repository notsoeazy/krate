import 'dart:ui';
import 'package:flutter/material.dart';

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
    Widget content = Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.white),
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
