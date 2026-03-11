import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Requests the necessary storage permissions for Android.
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

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
