import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/providers/providers.dart';
import 'package:permission_handler/permission_handler.dart';

class StorageSetupScreen extends ConsumerStatefulWidget {
  const StorageSetupScreen({super.key});

  @override
  ConsumerState<StorageSetupScreen> createState() => _StorageSetupScreenState();
}

class _StorageSetupScreenState extends ConsumerState<StorageSetupScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _pickDirectory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        // Request both simultaneously to handle older and newer Android versions
        await [Permission.storage, Permission.manageExternalStorage].request();

        final storageGranted = await Permission.storage.isGranted;
        final manageGranted = await Permission.manageExternalStorage.isGranted;

        if (!storageGranted && !manageGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Storage permission is required to manage your media vault. Please enable it in settings.',
                ),
                action: SnackBarAction(
                  label: 'Settings',
                  onPressed: () => openAppSettings(),
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
          setState(() {
            _error = 'Storage permission was denied.';
            _isLoading = false;
          });
          return;
        }
      }

      final path = await FilePicker.platform.getDirectoryPath();
      if (path == null) {
        setState(() => _isLoading = false);
        return;
      }

      final alreadyExists = await ref
          .read(storageServiceProvider)
          .setRoot(path);

      if (alreadyExists && mounted) {
        final shouldSync = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Existing Vault Found'),
            content: const Text(
              'A Krate vault already exists in this directory. Would you like to sync your library now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sync Now'),
              ),
            ],
          ),
        );

        if (shouldSync == true && mounted) {
          // Trigger sync in the background or show progress
          // For now, we'll just start it and move on, or we could wait.
          // Since it's initial setup, let's just trigger it.
          ref.read(vaultSyncProvider.notifier).sync();
        }
      }

      ref.invalidate(vaultStatusProvider);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Storage Icon
                CircleAvatar(
                  radius: 52,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.folder_zip_outlined,
                    size: 52,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 32),
                // Welcome Text
                Text(
                  'Welcome to Krate',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Krate needs a storage directory to save your media metadata '
                  'and artwork. Select a folder to begin.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),
                // Actions
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  FilledButton.icon(
                    onPressed: _pickDirectory,
                    icon: const Icon(Icons.folder_open_outlined),
                    label: const Text('Choose Storage Location'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
