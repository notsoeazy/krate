import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storagePath = ref.watch(storageServiceProvider).getRoot();
    final scannerState = ref.watch(scannerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Storage Section
          _Header(title: 'Storage'),
          FutureBuilder<String?>(
            future: storagePath,
            builder: (context, snapshot) => ListTile(
              title: const Text('Storage Location'),
              subtitle: Text(snapshot.data ?? 'Not set'),
              leading: const Icon(Icons.folder_open),
              onTap: () {
                // TODO: Allow re-picking root
              },
            ),
          ),
          ListTile(
            title: const Text('Scan Library'),
            subtitle: scannerState.isScanning
                ? Text(
                    '${scannerState.status} (${(scannerState.progress * 100).toInt()}%)',
                  )
                : const Text('Force a full reconciliation of the vault'),
            leading: const Icon(Icons.refresh),
            trailing: scannerState.isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: scannerState.isScanning
                ? null
                : () => ref.read(scannerProvider.notifier).scan(),
          ),

          const Divider(),

          // Appearance
          _Header(title: 'Appearance'),
          const ListTile(
            title: Text('Theme'),
            subtitle: Text('Dark Mode (default)'),
            leading: Icon(Icons.color_lens_outlined),
            enabled: false,
          ),

          const Divider(),

          // About
          _Header(title: 'About'),
          const ListTile(
            title: Text('Krate Version'),
            subtitle: Text('0.2.0-rewrite'),
            leading: Icon(Icons.info_outline),
          ),
          ListTile(
            title: const Text('Reset Database'),
            subtitle: const Text(
              'Wipes the SQLite cache. Scribe files are safe.',
            ),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () {
              // TODO: Implement DB wipe
            },
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
