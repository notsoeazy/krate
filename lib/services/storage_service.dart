import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

/// Manages the user-selected base directory for media storage.
///
/// The user picks a directory once, and Krate stores everything
/// inside a hidden `.krate/` subfolder.
class StorageService extends ChangeNotifier {
  static const String _storageRootKey = 'krate_storage_root';

  /// Saves the user-selected root path to persistent storage.
  Future<void> setStorageRoot(String path) async {
    // 1. Validate write permission immediately
    final testFile = File(
      '$path/.krate_test_${DateTime.now().millisecondsSinceEpoch}',
    );
    try {
      await testFile.writeAsString('permission_test');
      await testFile.delete();
    } catch (e) {
      throw FileSystemException(
        'Krate does not have permission to write to this directory. '
        'Please select a different location with write access.',
        path,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageRootKey, path);

    // 2. Ensure the .krate directory exists
    final krateDir = Directory('$path/.krate');
    if (!await krateDir.exists()) {
      await krateDir.create(recursive: true);
    }

    notifyListeners();
  }

  /// Returns the user-selected root path, or null if not yet set.
  Future<String?> getStorageRoot() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageRootKey);
  }

  /// Returns the absolute path to the hidden `.krate` directory.
  ///
  /// Throws a [StateError] if the storage root hasn't been set.
  Future<String> getKrateDir() async {
    final root = await getStorageRoot();
    if (root == null) {
      throw StateError(
        'Storage root not set. User must select a directory first.',
      );
    }
    return '$root/.krate';
  }

  /// Helper to check if the app is ready for imports.
  Future<bool> isStorageReady() async {
    final root = await getStorageRoot();
    if (root == null) return false;
    final krateDir = Directory('$root/.krate');
    return await krateDir.exists();
  }

  /// Verifies the storage root exists, otherwise clears it.
  /// Useful for startup/resume checks.
  Future<bool> verifyStorageRoot() async {
    final root = await getStorageRoot();
    if (root == null) return false;

    if (!await Directory(root).exists()) {
      debugPrint('Storage root missing, resetting...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageRootKey);
      notifyListeners();
      return false;
    }
    return true;
  }
}
