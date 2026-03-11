import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';

/// A global overlay that sits above every route to show toast notifications.
class GlobalToastOverlay extends ConsumerWidget {
  final Widget child;

  const GlobalToastOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both import toasts and a new generic toast provider (to be added)
    final importJob = ref.watch(importToastProvider);
    final vaultSyncState = ref.watch(vaultSyncProvider);

    return Stack(
      children: [
        child,
        
        // Vault Sync Notification
        if (vaultSyncState.isSyncing)
          _ToastWrapper(
            child: _SyncToast(
              status: vaultSyncState.status,
              progress: vaultSyncState.progress,
            ),
          ),

        // Import Job Notification
        if (importJob != null)
          _ToastWrapper(
            child: _ImportToast(
              jobTitle: importJob.title,
              status: importJob.currentStep ?? 'Running...',
              isError: importJob.hasFailed,
              onClose: () => ref.read(importToastProvider.notifier).dismiss(),
            ),
          ),
      ],
    );
  }
}

class _ToastWrapper extends StatelessWidget {
  final Widget child;
  const _ToastWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            tween: Tween(begin: -100.0, end: 0.0),
            builder: (context, offset, child) =>
                Transform.translate(offset: Offset(0, offset), child: child),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SyncToast extends StatelessWidget {
  final String status;
  final double progress;

  const _SyncToast({required this.status, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress > 0 && progress < 1 ? progress : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vault Sync', style: theme.textTheme.titleSmall),
                  Text(
                    status,
                    style: theme.textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportToast extends StatelessWidget {
  final String jobTitle;
  final String status;
  final bool isError;
  final VoidCallback onClose;

  const _ImportToast({
    required this.jobTitle,
    required this.status,
    required this.isError,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: isError ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(jobTitle, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isError ? theme.colorScheme.error : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
