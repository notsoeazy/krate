import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:krate/services/storage_service.dart';
import 'package:krate/services/permission_service.dart';

class StorageSelectionScreen extends StatefulWidget {
  const StorageSelectionScreen({super.key});

  @override
  State<StorageSelectionScreen> createState() => _StorageSelectionScreenState();
}

class _StorageSelectionScreenState extends State<StorageSelectionScreen> {
  bool _isPicking = false;

  Future<void> _pickFolder() async {
    setState(() => _isPicking = true);

    try {
      // 1. Request Android Permissions first
      final granted = await PermissionService.requestStoragePermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Storage permission is required to manage your media vault. "
              "Please enable it in App Settings.",
            ),
          ),
        );
        setState(() => _isPicking = false);
        return;
      }

      final String? selectedDirectory = await FilePicker.platform
          .getDirectoryPath();

      if (selectedDirectory != null && mounted) {
        await context.read<StorageService>().setStorageRoot(selectedDirectory);
        // No need to pop anymore, KrateApp is reactive!
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e is FileSystemException
            ? e.message
            : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primaryContainer.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon / Logo Placeholder
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Welcome to Krate",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "To start your media vault, please select a directory where your movies and series will be managed.",
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.5,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "A hidden .krate folder will be created inside.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _isPicking ? null : _pickFolder,
                icon: _isPicking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.drive_file_move_rounded),
                label: Text(
                  _isPicking ? "Opening Picker..." : "Select Vault Directory",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
