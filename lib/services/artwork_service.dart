import 'dart:io';
import 'package:dio/dio.dart';
import 'package:krate/models/app/content.dart';

/// Handles downloading and caching TMDB poster/backdrop images to custom storage.
///
/// Saved structure within the user-selected root:
///   <krateDir>/.artwork/<sanitized_title>/...
class ArtworkService {
  final Dio _dio = Dio();

  static const String _tmdbImageBaseUrl = 'https://image.tmdb.org/t/p';
  static const String _posterSize = 'w500';
  static const String _backdropSize = 'w780';

  String getPosterUrl(String tmdbPath) =>
      '$_tmdbImageBaseUrl/$_posterSize$tmdbPath';
  String getBackdropUrl(String tmdbPath) =>
      '$_tmdbImageBaseUrl/$_backdropSize$tmdbPath';

  Future<({String? posterPath, String? backdropPath})> downloadArtwork({
    required Content content,
    String? posterTmdbPath,
    String? backdropTmdbPath,
    required String targetDirectory,
  }) async {
    final results = await Future.wait([
      posterTmdbPath != null
          ? _downloadImage(
              url: getPosterUrl(posterTmdbPath),
              targetDirectory: targetDirectory,
              filename: '.poster.jpg',
            )
          : Future.value(null),
      backdropTmdbPath != null
          ? _downloadImage(
              url: getBackdropUrl(backdropTmdbPath),
              targetDirectory: targetDirectory,
              filename: '.backdrop.jpg',
            )
          : Future.value(null),
    ]);
    return (posterPath: results[0], backdropPath: results[1]);
  }

  Future<void> deleteArtwork(String targetDirectory) async {
    try {
      final poster = File('$targetDirectory/.poster.jpg');
      final backdrop = File('$targetDirectory/.backdrop.jpg');
      if (await poster.exists()) await poster.delete();
      if (await backdrop.exists()) await backdrop.delete();
    } catch (_) {}
  }

  Future<String?> _downloadImage({
    required String url,
    required String targetDirectory,
    required String filename,
  }) async {
    try {
      final dir = Directory(targetDirectory);
      if (!await dir.exists()) await dir.create(recursive: true);

      final filePath = '$targetDirectory/$filename';
      final file = File(filePath);

      if (await file.exists()) return filePath;

      await _dio.download(url, filePath);
      return filePath;
    } catch (_) {
      return null;
    }
  }
}
