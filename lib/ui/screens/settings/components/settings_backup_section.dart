import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/widgets/confirmation_dialog.dart';
import 'package:krate/utils/extensions.dart';

class SettingsBackupSection extends ConsumerWidget {
  const SettingsBackupSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastBackupTime = ref.watch(lastBackupTimeProvider);
    final syncState = ref.watch(vaultSyncProvider);
    final isSyncing = syncState.isSyncing;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            title: const Text('Backup Database'),
            subtitle: isSyncing
                ? const Text('Vault sync in progress...')
                : lastBackupTime.when(
                  data: (time) => Text(
                    time != null
                        ? 'Last backup: ${time.toBackupFormat()}'
                        : 'No backup found',
                  ),
                  loading: () => const Text('Checking backup status...'),
                  error: (_, _) => const Text('Error checking backup'),
                ),
            leading: const Icon(Icons.backup_outlined),
            enabled: !isSyncing,
            onTap: isSyncing ? null : () => _handleBackup(context, ref),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            title: const Text('Restore Database'),
            subtitle: Text(
              isSyncing
                  ? 'Waiting for vault sync...'
                  : 'Load data from krate_backup.json',
            ),
            leading: const Icon(Icons.settings_backup_restore_outlined),
            enabled: !isSyncing,
            onTap: isSyncing ? null : () => _handleRestore(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackup(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(backupServiceProvider).createBackup();
      ref.invalidate(lastBackupTimeProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup created successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Restore Database?',
      message:
          'This will overwrite your current library and watch progress with the data from the backup file. This action cannot be undone.',
      confirmLabel: 'Restore',
    );

    if (confirmed == true) {
      try {
        await ref.read(backupServiceProvider).loadBackup();

        // Invalidate all providers to refresh the app state
        ref.invalidate(moviesProvider);
        ref.invalidate(seriesProvider);
        ref.invalidate(recentMoviesProvider);
        ref.invalidate(recentSeriesProvider);
        ref.invalidate(continueWatchingProvider);
        ref.invalidate(watchHistoryListProvider);
        ref.invalidate(watchingContentProvider);
        ref.invalidate(completedContentProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Database restored successfully')),
          );
        }
      } catch (e) {
        if (e.toString().contains('Backup file not found')) {
          ref.invalidate(lastBackupTimeProvider);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
        }
      }
    }
  }
}
