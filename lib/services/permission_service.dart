import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Requests the necessary storage permissions for Android.
  ///
  /// On Android 11+ (API 30+), it requests [Permission.manageExternalStorage].
  /// On older versions, it requests [Permission.storage].
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // For Android 11 and above, we ideally want Manage External Storage
    // but we can try basic storage first if thats what the user prefers.
    // However, for a "Vault" app, Manage is best.
    final status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      return true;
    }

    // Fallback/Legacy storage permission
    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) return true;

    // Android 13+ granular permissions
    if (Platform.isAndroid) {
      final videosStatus = await Permission.videos.request();
      return videosStatus.isGranted;
    }

    return false;
  }

  static Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) return true;

    return await Permission.manageExternalStorage.isGranted ||
        await Permission.storage.isGranted ||
        await Permission.videos.isGranted;
  }
}
