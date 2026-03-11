import 'package:flutter/material.dart';

class AppearanceSettingsCard extends StatelessWidget {
  const AppearanceSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: const ListTile(
        title: Text('Theme'),
        subtitle: Text('Dark Mode (default)'),
        leading: Icon(Icons.color_lens_outlined),
        enabled: false,
      ),
    );
  }
}
