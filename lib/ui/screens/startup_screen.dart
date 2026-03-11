import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:krate/ui/screens/shell_screen.dart';

class StartupScreen extends ConsumerStatefulWidget {
  const StartupScreen({super.key});

  @override
  ConsumerState<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends ConsumerState<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _scoutVault();
  }

  Future<void> _scoutVault() async {
    final syncService = ref.read(vaultSyncServiceProvider);
    final needsSync = await syncService.scout();
    
    if (mounted) {
      if (needsSync) {
        // Capture the provider container since this widget will be disposed
        // immediately after we push Replacement the ShellScreen.
        final container = ProviderScope.containerOf(context);
        
        // Just notify the user via a global SnackBar that a sync might be needed.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vault directory changes detected.'),
            action: SnackBarAction(
              label: 'Sync Now',
              onPressed: () {
                container.read(vaultSyncProvider.notifier).sync();
              },
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      _navigateToApp();
    }
  }

  void _navigateToApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const ShellScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              // App Name
              Text(
                'Krate',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 48),
              // Loading Spinner
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
