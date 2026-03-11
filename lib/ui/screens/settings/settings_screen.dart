import 'package:flutter/material.dart';

import 'package:krate/ui/widgets/settings_section_header.dart';
import 'package:krate/ui/widgets/settings_storage_card.dart';
import 'package:krate/ui/widgets/settings_about_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          // Storage
          SettingsSectionHeader(title: 'Storage'),
          StorageSettingsCard(),

          SizedBox(height: 8),

          // About
          SettingsSectionHeader(title: 'About'),
          AboutSettingsCard(),

          SizedBox(height: 24),
        ],
      ),
    );
  }
}
