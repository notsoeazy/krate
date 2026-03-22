import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/theme.dart';

class SettingsAppearanceSection extends ConsumerWidget {
  const SettingsAppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeSchemeIndex = ref.watch(themeSchemeProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_themeModeName(themeMode)),
            leading: const Icon(Icons.brightness_medium),
            onTap: () => _showThemeModeDialog(context, ref, themeMode),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            title: const Text('Color Scheme'),
            subtitle: Text(MaterialTheme.schemes[themeSchemeIndex].name),
            leading: const Icon(Icons.color_lens),
            onTap: () => _showColorSchemeDialog(context, ref, themeSchemeIndex),
          ),
        ],
      ),
    );
  }

  String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeModeDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: (value) {
            if (value != null) {
              ref.read(themeModeProvider.notifier).setThemeMode(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((mode) {
              return RadioListTile<ThemeMode>(
                title: Text(_themeModeName(mode)),
                value: mode,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showColorSchemeDialog(
    BuildContext context,
    WidgetRef ref,
    int current,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Select Color Scheme'),
          content: RadioGroup<int>(
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(themeSchemeProvider.notifier)
                    .setThemeSchemeIndex(value);
                Navigator.pop(context);
              }
            },
            child: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: MaterialTheme.schemes.length,
                itemBuilder: (context, index) {
                  final scheme = MaterialTheme.schemes[index];
                  return RadioListTile<int>(
                    title: Text(scheme.name),
                    value: index,
                    secondary: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            theme.brightness == Brightness.light
                                ? scheme.light().primary
                                : scheme.dark().primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
