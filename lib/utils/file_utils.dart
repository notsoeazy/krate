import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/utils/errors.dart';

class KrateFile {
  final String name;
  final String uri;
  final String? path;
  final int size;

  KrateFile({
    required this.name,
    required this.uri,
    this.path,
    required this.size,
  });

  String get extension => name.split('.').last.toLowerCase();

  /// Returns the most 'physical' path available.
  /// Prioritizes the resolved real path over the URI.
  String get bestPath => (path != null && path!.isNotEmpty) ? path! : uri;

  @override
  String toString() => 'KrateFile(name: $name, uri: $uri, path: $path, size: $size)';
}

class FileUtils {
  static const _channel = MethodChannel('com.notsoeazy.krate/file_utils');

  /// Attempts to resolve a real filesystem path from a URI (e.g. content:// on Android).
  /// If [uri] is already a file path or resolution fails, it returns the original path.
  static Future<String?> getRealPath(String? uri) async {
    if (uri == null) return null;
    if (!Platform.isAndroid) return uri;
    if (!uri.startsWith('content://')) return uri;

    try {
      final String? path = await _channel.invokeMethod('getRealPath', {'uri': uri});
      return path ?? uri;
    } catch (e) {
      // Fallback to original URI if resolution fails
      return uri;
    }
  }

  /// Launches a native file picker on Android to bypass the 'file_picker' caching.
  /// Falls back to 'file_picker' plugin on other platforms or if native picker fails.
  static Future<List<KrateFile>?> pickFiles({
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    if (Platform.isAndroid) {
      try {
        final List<dynamic>? result = await _channel.invokeMethod('pickFiles', {
          'allowedExtensions': allowedExtensions,
          'allowMultiple': allowMultiple,
        });

        if (result != null) {
          return result.map((item) {
            final map = Map<String, dynamic>.from(item);
            final path = map['path'] as String?;
            return KrateFile(
              name: map['name'] ?? '',
              uri: map['uri'] ?? '',
              path: (path != null && path.isNotEmpty) ? path : null,
              size: int.tryParse(map['size']?.toString() ?? '0') ?? 0,
            );
          }).toList();
        }

        // result is null, user cancelled.
        return null; 
      } catch (e) {
        // Fallback to file_picker if native fails
      }
    }

    // Fallback/Default implementation using file_picker
    final result = await FilePicker.platform.pickFiles(
      type: allowedExtensions != null ? FileType.custom : FileType.any,
      allowedExtensions: allowedExtensions,
      allowMultiple: allowMultiple,
    );

    if (result == null) return null;

    return result.files.map((f) => KrateFile(
      name: f.name,
      uri: f.identifier ?? f.path ?? '',
      path: f.path,
      size: f.size,
    )).toList();
  }

  /// Specialized picker for 1 Video + N Subtitles.
  /// Centralizes validation, logging, and filtering.
  static Future<({String videoPath, List<String> subtitlePaths})?> pickVideoWithSubtitles({
    String debugLabel = 'Picker',
  }) async {
    final result = await pickFiles(
      allowedExtensions: [...kAllowedVideoExtensions, ...kAllowedSubtitleExtensions],
      allowMultiple: true,
    );

    if (result == null || result.isEmpty) return null;

    final videoFiles = result.where((f) => kAllowedVideoExtensions.contains(f.extension)).toList();
    final subtitleFiles = result.where((f) => kAllowedSubtitleExtensions.contains(f.extension)).toList();

    // Log the selection
    debugPrint('[$debugLabel] Selection:');
    for (final f in result) {
      final isVideo = kAllowedVideoExtensions.contains(f.extension);
      debugPrint('  - [${isVideo ? "VIDEO" : "SUB"}] ${f.name} | Best Path: ${f.bestPath}');
    }

    if (videoFiles.isEmpty) {
      throw const VideoRequiredException();
    }

    if (videoFiles.length > 1) {
      throw const FilePickingException('Please select only one video file.');
    }

    return (
      videoPath: videoFiles.first.bestPath,
      subtitlePaths: subtitleFiles.map((f) => f.bestPath).toList(),
    );
  }

  /// Specialized picker for N Subtitles only.
  static Future<List<String>?> pickSubtitlesOnly({
    String debugLabel = 'SubtitlePicker',
  }) async {
    final result = await pickFiles(
      allowedExtensions: kAllowedSubtitleExtensions,
      allowMultiple: true,
    );

    if (result == null || result.isEmpty) return null;

    // Log the selection
    debugPrint('[$debugLabel] Subtitles Picked:');
    final paths = <String>[];
    for (final f in result) {
      if (kAllowedSubtitleExtensions.contains(f.extension)) {
        paths.add(f.bestPath);
        debugPrint('  - ${f.name} | Path: ${f.bestPath}');
      } else {
        debugPrint('  - IGNORING: ${f.name} (Invalid extension)');
      }
    }

    return paths.isNotEmpty ? paths : null;
  }
}
