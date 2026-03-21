import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/home/home_screen.dart';
import 'package:krate/ui/screens/library/library_screen.dart';
import 'package:krate/ui/screens/recents/recents_screen.dart';
import 'package:krate/ui/screens/settings/settings_screen.dart';
import 'package:krate/ui/screens/import/components/import_overlay.dart';

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  final List<Widget> _screens = const [
    HomeScreen(),
    LibraryScreen(),
    RecentsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(shellTabIndexProvider);

    // Watch for vault changes detected during startup scan
    final changesDetected = ref.watch(vaultChangesDetectedProvider);
    if (changesDetected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Reset immediately to prevent duplicate dialogs
        ref.read(vaultChangesDetectedProvider.notifier).state = false;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Sync Required'),
            content: const Text(
              'Changes or an existing library were detected in your vault '
              'directory. Sync now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(vaultSyncProvider.notifier).sync();
                },
                child: const Text('Sync Now'),
              ),
            ],
          ),
        );
      });
    }

    final destinations = [
      const _NavigationDestinationData(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
      ),
      const _NavigationDestinationData(
        icon: Icons.movie_outlined,
        selectedIcon: Icons.movie,
        label: 'Library',
      ),
      const _NavigationDestinationData(
        icon: Icons.history_outlined,
        selectedIcon: Icons.history,
        label: 'Recents',
      ),
      const _NavigationDestinationData(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: 'Settings',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        return Scaffold(
          body: Row(
            children: [
              if (isWide)
                NavigationRail(
                  selectedIndex: currentIndex,
                  groupAlignment: 0.0,
                  onDestinationSelected: (index) {
                    ref.read(shellTabIndexProvider.notifier).state = index;
                  },
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations
                      .map(
                        (d) => NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon),
                          label: Text(d.label),
                        ),
                      )
                      .toList(),
                ),
              Expanded(
                child: ImportOverlay(
                  child: IndexedStack(index: currentIndex, children: _screens),
                ),
              ),
            ],
          ),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: currentIndex,
                  onDestinationSelected: (index) {
                    ref.read(shellTabIndexProvider.notifier).state = index;
                  },
                  destinations: destinations
                      .map(
                        (d) => NavigationDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon),
                          label: d.label,
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }
}

class _NavigationDestinationData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavigationDestinationData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
