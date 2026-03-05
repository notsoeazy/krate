import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart';

class StorageService {
  static const _storageKey = "app_storage_root";

  Future<void> setRootDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, path);
  }

  Future<String?> getRootDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageKey);
  }

  Future<void> initializeStorage() async {
    final root = await getRootDirectory();
    if (root == null) {
      throw Exception("Storage root not set");
    }

    final moviesDir = Directory(join(root, "movies"));
    final seriesDir = Directory(join(root, "series"));

    if (!await moviesDir.exists()) {
      await moviesDir.create(recursive: true);
    }

    if (!await seriesDir.exists()) {
      await seriesDir.create(recursive: true);
    }
  }

  Future<bool> storageExists() async {
    final root = await getRootDirectory();
    if (root == null) return false;

    final moviesDir = Directory(join(root, "movies"));
    final seriesDir = Directory(join(root, "series"));

    return await moviesDir.exists() && await seriesDir.exists();
  }
}
