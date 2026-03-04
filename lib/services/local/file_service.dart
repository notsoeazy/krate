import 'dart:io';
import 'package:path/path.dart' as p;

/// Handles all file and folder operations for local content storage
class FileService {
  /// Create the main app structure:
  /// basePath/content/movies, /series, /anime
  Future<void> createAppStructure(String basePath) async {
    final contentDir = Directory(p.join(basePath, 'content'));
    final moviesDir = Directory(p.join(contentDir.path, 'movies'));
    final seriesDir = Directory(p.join(contentDir.path, 'series'));
    final animeDir = Directory(p.join(contentDir.path, 'anime'));

    for (final dir in [contentDir, moviesDir, seriesDir, animeDir]) {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        print('Created folder: ${dir.path}');
      }
    }
  }

  /// Move a single file to destination folder and optionally rename it
  /// Returns the moved file
  Future<File> moveAndRenameFile({
    required String sourcePath,
    required String destDir,
    String? newFileName,
    bool overwrite = false,
  }) async {
    final file = File(sourcePath);

    if (!await file.exists()) {
      throw FileSystemException('Source file does not exist', sourcePath);
    }

    final fileName = newFileName ?? p.basename(sourcePath);
    final newPath = p.join(destDir, fileName);
    final newFile = File(newPath);

    if (await newFile.exists()) {
      if (overwrite) {
        await newFile.delete();
      } else {
        throw FileSystemException('File already exists', newPath);
      }
    }

    return await file.rename(newPath);
  }

  /// Create a subfolder under a parent directory if it doesn't exist
  /// Returns the Directory object
  Future<Directory> createSubFolder(String parentDir, String folderName) async {
    final dir = Directory(p.join(parentDir, folderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      print('Created subfolder: ${dir.path}');
    }
    return dir;
  }

  /// Utility: Get path for content type folder
  String getContentTypeFolder(String basePath, String contentType) {
    switch (contentType.toLowerCase()) {
      case 'movie':
      case 'movies':
        return p.join(basePath, 'content', 'movies');
      case 'series':
        return p.join(basePath, 'content', 'series');
      case 'anime':
        return p.join(basePath, 'content', 'anime');
      default:
        return p.join(basePath, 'content', contentType.toLowerCase());
    }
  }
}
