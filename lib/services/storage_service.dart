import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/utils/errors.dart';
import 'package:krate/data/models/content.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:krate/utils/extensions.dart';

enum VaultStatus { ok, rootMissing, noPermission }

// Manages the user-selected storage root and the on-disk vault structure.
// The vault lives at:
//   `<userRoot>/krate_vault/movies/`
//   `<userRoot>/krate_vault/series/`
// The SQLite database is stored separately in the OS app-data directory.
class StorageService {
  static const _rootKey = 'krate_storage_root';

  // Root setup & verification

  // Persists [path] as the storage root after verifying write access
  // and creating the vault folder structure.
  Future<bool> setRoot(String path) async {
    var rootPath = path;
    // If the user selected the krate_vault folder itself, go up one level
    final dir = Directory(path);
    if (dir.path.split(Platform.pathSeparator).last == kVaultFolderName) {
      rootPath = dir.parent.path;
      debugPrint('[StorageService] Selected krate_vault, using parent: $rootPath');
    }

    // Validate write permission
    final testFile = File(
      '$rootPath/.krate_permission_test_${DateTime.now().millisecondsSinceEpoch}',
    );
    try {
      await testFile.writeAsString('ok');
      await testFile.delete();
    } catch (_) {
      throw VaultPermissionException(rootPath);
    }

    // Check if vault already exists
    final vaultDir = Directory('$rootPath/$kVaultFolderName');
    final alreadyExists = await vaultDir.exists();

    // Persist the path
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rootKey, rootPath);

    // Create/Ensure the directory structure
    await _ensureVaultStructure(rootPath);

    return alreadyExists;
  }

  Future<String?> getRoot() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rootKey);
  }

  Future<void> clearRoot() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rootKey);
  }

  // Checks vault integrity and returns the appropriate [VaultStatus].
  // Called on every app launch to decide whether to show the main shell
  // or redirect to [StorageSetupScreen].
  Future<VaultStatus> checkIntegrity() async {
    debugPrint('[StorageService] Checking vault integrity...');
    final root = await getRoot();
    debugPrint('[StorageService] Root path: $root');
    if (root == null) return VaultStatus.rootMissing;

    if (Platform.isAndroid) {
      debugPrint('[StorageService] Checking Android permissions...');
      if (!await Permission.storage.isGranted) {
        // On Android 11+, check for Manage External Storage
        if (!await Permission.manageExternalStorage.isGranted) {
          return VaultStatus.noPermission;
        }
      }
    }

    if (!await Directory(root).exists()) {
      debugPrint('[StorageService] Root missing, clearing saved path.');
      await clearRoot();
      return VaultStatus.rootMissing;
    }

    // Verify write access
    final testFile = File(
      '$root/.krate_check_${DateTime.now().millisecondsSinceEpoch}',
    );
    try {
      await testFile.writeAsString('ok');
      await testFile.delete();
    } catch (_) {
      return VaultStatus.noPermission;
    }

    // Ensure folder structure exists (recreate if accidentally deleted)
    await _ensureVaultStructure(root);
    return VaultStatus.ok;
  }

  Future<String> _vaultRoot() async {
    final root = await getRoot();
    if (root == null) throw StateError('Storage root not configured');
    return '$root/$kVaultFolderName';
  }

  // Returns the absolute path to the movies sub-directory.
  Future<String> getMoviesDir() async =>
      '${await _vaultRoot()}/$kMoviesDirName';

  // Returns the absolute path to the series sub-directory.
  Future<String> getSeriesDir() async =>
      '${await _vaultRoot()}/$kSeriesDirName';

  // Computes and ensures the pod directory for [content] exists.
  // Naming convention: `Title_Year_TMDBID`
  Future<String> ensurePodDir(Content content) async {
    final safeTitle = content.title.toSlug();
    final year = content.releaseDate?.year ?? 0;
    final tmdbId = content.tmdbId ?? 0;
    final folderName = '${safeTitle}_${year}_$tmdbId';

    final parentDir = content.contentType == ContentType.movie
        ? await getMoviesDir()
        : await getSeriesDir();

    final podDir = Directory('$parentDir/$folderName');
    await podDir.create(recursive: true);
    return podDir.path;
  }

  // Creates the season sub-folder inside a series pod and returns its path.
  Future<String> ensureSeasonDir(String podPath, int seasonNumber) async {
    final seasonStr = 'Season_${seasonNumber.toString().padLeft(2, '0')}';
    final dir = Directory('$podPath/$seasonStr');
    await dir.create(recursive: true);
    return dir.path;
  }

  // Returns the destination file path for a movie, preserving its original name.
  Future<String> movieFilePath(
    Content content,
    String podPath,
    String sourceFilePath,
  ) async {
    final fileName = sourceFilePath.split(Platform.pathSeparator).last;
    return '$podPath/$fileName';
  }

  // Returns the destination file path for a series episode, preserving its original name.
  Future<String> episodeFilePath(
    Content content,
    String podPath,
    int season,
    int episode,
    String sourceFilePath,
  ) async {
    final fileName = sourceFilePath.split(Platform.pathSeparator).last;
    final seasonDir = await ensureSeasonDir(podPath, season);
    final episodeStr =
        '$kEpisodeDirPrefix${episode.toString().padLeft(2, '0')}';
    final episodeDir = Directory('$seasonDir/$episodeStr');
    await episodeDir.create(recursive: true);
    return '${episodeDir.path}/$fileName';
  }

  // Private helpers

  // Wipes the app's temporary/cache directory.
  // Useful for cleaning up orphans from failed imports or file picker leaks.
  Future<void> cleanTemporaryDirectory() async {
    try {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (final entity in tempDir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (e) {
            debugPrint(
              '[StorageService] Could not delete temp entity ${entity.path}: $e',
            );
          }
        }
        debugPrint('[StorageService] Temporary directory cleaned.');
      }
    } catch (e) {
      debugPrint('[StorageService] Failed to clean temporary directory: $e');
    }
  }

  Future<void> _ensureVaultStructure(String root) async {
    await Directory(
      '$root/$kVaultFolderName/$kMoviesDirName',
    ).create(recursive: true);
    await Directory(
      '$root/$kVaultFolderName/$kSeriesDirName',
    ).create(recursive: true);
  }
}
