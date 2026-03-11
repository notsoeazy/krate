import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storagePath = ref.watch(storageServiceProvider).getRoot();
    final scannerState = ref.watch(vaultSyncProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Storage ──────────────────────────────────────────────────
          _SectionHeader(title: 'Storage'),
          Card(
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
          ),

          const SizedBox(height: 8),

          // ── Appearance ───────────────────────────────────────────────
          _SectionHeader(title: 'Appearance'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: const ListTile(
              title: Text('Theme'),
              subtitle: Text('Dark Mode (default)'),
              leading: Icon(Icons.color_lens_outlined),
              enabled: false,
            ),
          ),

          const SizedBox(height: 8),

          // ── About ────────────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                const ListTile(
                  title: Text('Krate Version'),
                  subtitle: Text('0.2.0-rewrite'),
                  leading: Icon(Icons.info_outline),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  title: const Text('Reset Database'),
                  subtitle: const Text(
                    'Wipes the SQLite cache. Scribe files are safe.',
                  ),
                  // colorScheme.error used instead of Colors.red
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: theme.colorScheme.error,
                  ),
                  onTap: () {
                    // TODO: Implement DB wipe
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// M3-compliant section header: uses [labelMedium] + [colorScheme.primary].
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
