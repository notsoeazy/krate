import 'dart:io';
import 'package:dio/dio.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/services/tmdb_service.dart';

// Downloads TMDB artwork (poster and backdrop) into a pod directory.
class ArtworkService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  // Downloads poster and backdrop for content into podPath.
  // Returns a record with the absolute paths to the saved files, or null
  // for each if the download failed or the path was not provided.
  Future<({String? posterPath, String? backdropPath})> downloadArtwork({
    required String? tmdbPosterPath,
    required String? tmdbBackdropPath,
    required String podPath,
    bool overwrite = false,
  }) async {
    final dir = Directory(podPath);
    if (!await dir.exists()) await dir.create(recursive: true);

    final results = await Future.wait([
      tmdbPosterPath != null
          ? _download(
              TMDBService.posterUrl(tmdbPosterPath),
              '$podPath/$kPosterFileName',
              overwrite: overwrite,
            )
          : Future.value(null),
      tmdbBackdropPath != null
          ? _download(
              TMDBService.backdropUrl(tmdbBackdropPath),
              '$podPath/$kBackdropFileName',
              overwrite: overwrite,
            )
          : Future.value(null),
    ]);

    return (posterPath: results[0], backdropPath: results[1]);
  }

  Future<String?> _download(
    String url,
    String savePath, {
    bool overwrite = false,
  }) async {
    try {
      final file = File(savePath);
      if (await file.exists()) {
        if (overwrite) {
          await file.delete();
        } else {
          return savePath; // already downloaded
        }
      }
      await _dio.download(url, savePath);
      return savePath;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteArtwork(String podPath) async {
    for (final name in [kPosterFileName, kBackdropFileName]) {
      final file = File('$podPath/$name');
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
  }
}
