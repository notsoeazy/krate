import 'package:flutter/material.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? secondaryMessage;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.message,
    this.secondaryMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Icon(
            icon,
            size: 64,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          // Primary message
          Text(
            message,
            style: secondaryMessage == null
                ? theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  )
                : theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (secondaryMessage != null) ...[
            const SizedBox(height: 8),
            // Secondary message
            Text(
              secondaryMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
