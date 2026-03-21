import 'package:flutter/material.dart';
import 'package:krate/ui/screens/settings/components/settings_about_section.dart';
import 'package:krate/ui/screens/settings/components/settings_storage_section.dart';
import 'package:krate/ui/screens/settings/components/settings_backup_section.dart';
import 'package:krate/ui/screens/settings/components/settings_debug_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Storage
          _settingsSectionHeader('Storage', context),
          SettingsStorageSection(),

          SizedBox(height: 8),

          // Backup
          _settingsSectionHeader('Backup', context),
          const SettingsBackupSection(),

          const SizedBox(height: 8),

          // Debug
          _settingsSectionHeader('Debug (UI Testing)', context),
          const SettingsDebugSection(),

          const SizedBox(height: 8),

          // About
          _settingsSectionHeader('About', context),
          SettingsAboutSection(),

          // SizedBox(height: 8),

          // Licenses
          // _settingsSectionHeader('License', context),
          // TODO: Implement licenses
        ],
      ),
    );
  }

  Widget _settingsSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
