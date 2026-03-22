import 'package:flutter/material.dart';

/// A utility class to provide standardized SnackBar feedback across the application.
/// Ensures consistent styling, duration, and behavior based on the Krate UI Feedback Guide.
class FeedbackUtils {
  static const Duration _defaultDuration = Duration(seconds: 4);
  static const Duration _errorDuration = Duration(seconds: 6);
  static const Duration _undoDuration = Duration(seconds: 5);

  /// Shows an informational, low-priority message.
  static void showInfoSnackBar(BuildContext context, String message, {SnackBarAction? action}) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: _defaultDuration,
          behavior: SnackBarBehavior.floating,
          action: action,
        ),
      );
  }

  /// Shows a success message, typically indicating a completed action.
  static void showSuccessSnackBar(BuildContext context, String message, {SnackBarAction? action}) {
    if (!context.mounted) return;
    
    final theme = Theme.of(context);
    
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: theme.colorScheme.onPrimary, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: TextStyle(color: theme.colorScheme.onPrimary))),
            ],
          ),
          backgroundColor: theme.colorScheme.primary,
          duration: _defaultDuration,
          behavior: SnackBarBehavior.floating,
          action: action,
        ),
      );
  }

  /// Shows an error message.
  /// Uses the theme's error colors to clearly indicate a problem.
  static void showErrorSnackBar(BuildContext context, String message, {Object? error, SnackBarAction? action}) {
    if (!context.mounted) return;
    
    if (error != null) {
      debugPrint('[FeedbackUtils] Error SnackBar: $message => $error');
    }
    
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.onError, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: theme.colorScheme.onError),
                ),
              ),
            ],
          ),
          backgroundColor: theme.colorScheme.error,
          duration: _errorDuration,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          action: action,
        ),
      );
  }

  /// Shows a confirmation message with an "Undo" action.
  /// Useful for actions like deleting, marking as watched, or clearing history.
  static void showUndoSnackBar(BuildContext context, String message, VoidCallback onUndo) {
    if (!context.mounted) return;
    
    final theme = Theme.of(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: _undoDuration,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'UNDO',
            textColor: theme.colorScheme.primary,
            onPressed: onUndo,
          ),
        ),
      );
  }
}
