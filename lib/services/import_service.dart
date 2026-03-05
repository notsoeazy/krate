import 'dart:io';

import 'package:krate/services/path_service.dart';
import 'package:krate/services/file_service.dart';
import 'package:krate/services/image_download_service.dart';
import 'package:krate/utils/title_cleaner.dart';

class ImportService {
  final PathService pathService;
  final FileService fileService;
  final ImageDownloadService imageService;

  ImportService({
    required this.pathService,
    required this.fileService,
    required this.imageService,
  });

  /// Save a movie video and download images
  Future<String> importMovie({
    required int tmdbId,
    required String title,
    required File sourceVideo,
    required String posterPath,
    required String backdropPath,
  }) async {
    final cleanTitle = TitleCleaner.clean(title);

    // Ensure directories exist and save video
    final savedVideo = await fileService.saveMovieVideo(
      tmdbId,
      cleanTitle,
      sourceVideo,
    );

    // Download poster and backdrop
    if (posterPath.isNotEmpty) {
      await imageService.downloadMoviePoster(tmdbId, posterPath);
    }
    if (backdropPath.isNotEmpty) {
      await imageService.downloadMovieBackdrop(tmdbId, backdropPath);
    }

    return savedVideo.path;
  }

  /// Save a series episode video
  Future<String> importEpisode({
    required String seriesTitle,
    required int seriesId,
    required int seasonNumber,
    required int episodeNumber,
    required File sourceVideo,
  }) async {
    final cleanTitle = TitleCleaner.clean(seriesTitle);

    final savedVideo = await fileService.saveEpisodeVideo(
      cleanTitle,
      seriesId,
      seasonNumber,
      episodeNumber,
      sourceVideo,
    );

    return savedVideo.path;
  }

  /// Download series images (poster + backdrop)
  Future<void> setupSeriesImages({
    required int seriesId,
    required String posterPath,
    required String backdropPath,
  }) async {
    if (posterPath.isNotEmpty) {
      await imageService.downloadSeriesPoster(seriesId, posterPath);
    }
    if (backdropPath.isNotEmpty) {
      await imageService.downloadSeriesBackdrop(seriesId, backdropPath);
    }
  }
}
