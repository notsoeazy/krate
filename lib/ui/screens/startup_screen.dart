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
  bool _checkedDiscrepancies = false;
  bool _hasDiscrepancies = false;

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
        setState(() {
          _hasDiscrepancies = true;
          _checkedDiscrepancies = true;
        });
      } else {
        _navigateToApp();
      }
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
    final syncState = ref.watch(vaultSyncProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Krate',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 48),

              if (!_checkedDiscrepancies) ...[
                // Just show the logo while checking in the background
                const SizedBox.shrink(),
              ] else if (_hasDiscrepancies && !syncState.isSyncing) ...[
                const Icon(Icons.sync_problem, size: 48, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Vault changes detected',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The files in your vault don\'t match the database. Would you like to sync now?',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _navigateToApp,
                      child: const Text('Skip for now'),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: () => ref.read(vaultSyncProvider.notifier).sync(),
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync Vault'),
                    ),
                  ],
                ),
              ] else if (syncState.isSyncing) ...[
                LinearProgressIndicator(value: syncState.progress),
                const SizedBox(height: 16),
                Text(syncState.status),
                const SizedBox(height: 16),
                Text('${(syncState.progress * 100).toInt()}%'),
              ] else if (_checkedDiscrepancies && !_hasDiscrepancies) ...[
                const SizedBox.shrink(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
