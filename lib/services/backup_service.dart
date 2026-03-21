import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:krate/data/database/app_database.dart';
import 'package:krate/services/storage_service.dart';

class BackupService {
  final StorageService _storageService;
  final AppDatabase _db = AppDatabase.instance;

  BackupService(this._storageService);

  static const _backupFileName = 'krate_backup.json';

  Future<File> _getBackupFile() async {
    final root = await _storageService.getRoot();
    if (root == null) throw StateError('Storage root not configured');

    // Backup lives in the krate_vault folder
    return File('$root/krate_vault/$_backupFileName');
  }

  // Exports the entire database to a JSON file in the vault.
  Future<void> createBackup() async {
    final data = await _db.exportAllTables();
    final jsonString = jsonEncode(data);
    final file = await _getBackupFile();

    // Ensure parent directory exists (it should, but just in case)
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    await file.writeAsString(jsonString);
    debugPrint('[BackupService] Backup created at ${file.path}');
  }

  // Imports database data from the JSON file in the vault.
  Future<void> loadBackup() async {
    final file = await _getBackupFile();
    if (!await file.exists()) {
      throw FileSystemException('Backup file not found', file.path);
    }

    final jsonString = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(jsonString);

    // Basic validation: check if required tables are present
    final requiredTables = [
      'content',
      'episodes',
      'subtitles',
      'watch_progress',
      'watch_history',
    ];
    for (final table in requiredTables) {
      if (!data.containsKey(table)) {
        throw FormatException('Invalid backup file: Missing table "$table"');
      }
    }

    await _db.restoreAllTables(data);
    debugPrint('[BackupService] Backup restored from ${file.path}');
  }

  // Returns the last modification time of the backup file, or null if it doesn't exist.
  Future<DateTime?> getLastBackupTime() async {
    try {
      final file = await _getBackupFile();
      if (await file.exists()) {
        return await file.lastModified();
      }
    } catch (e) {
      debugPrint('[BackupService] Error checking backup time: $e');
    }
    return null;
  }
}
