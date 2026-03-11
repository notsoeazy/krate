import 'package:flutter/material.dart';

class AboutSettingsCard extends StatelessWidget {
  const AboutSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
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
    );
  }
}
