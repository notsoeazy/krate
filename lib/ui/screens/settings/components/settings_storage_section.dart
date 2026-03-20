import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';

class SettingsStorageSection extends ConsumerWidget {
  const SettingsStorageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storagePath = ref.watch(storageServiceProvider).getRoot();
    final scannerState = ref.watch(vaultSyncProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          FutureBuilder<String?>(
            future: storagePath,
            builder: (context, snapshot) => ListTile(
              title: const Text('Storage Location'),
              subtitle: Text(snapshot.data ?? 'Not set'),
              leading: const Icon(Icons.folder_open_outlined),
              onTap: () {
                // TODO: Allow re-picking root
              },
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            title: const Text('Vault Sync'),
            subtitle: scannerState.isSyncing
                ? Text(
                    '${scannerState.status} '
                    '(${(scannerState.progress * 100).toInt()}%)',
                  )
                : const Text('Sync local files with the database'),
            leading: const Icon(Icons.manage_search_outlined),
            trailing: scannerState.isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: scannerState.isSyncing
                ? null
                : () => ref.read(vaultSyncProvider.notifier).sync(),
          ),
        ],
      ),
    );
  }
}
