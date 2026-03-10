import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/home/home_screen.dart';
import 'package:krate/ui/screens/library/library_screen.dart';
import 'package:krate/ui/screens/recents/recents_screen.dart';
import 'package:krate/ui/screens/settings/settings_screen.dart';
import 'package:krate/ui/widgets/import_overlay.dart';

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

    return Scaffold(
      body: ImportOverlay(
        child: IndexedStack(index: currentIndex, children: _screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(shellTabIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Recents',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
