import 'dart:io';
import 'package:krate/services/path_service.dart';
import 'package:krate/services/directory_service.dart';

class FileService {
  final PathService pathService;
  final DirectoryService directoryService;

  FileService(this.pathService, this.directoryService);

  /// Save a movie video file
  Future<File> saveMovieVideo(int tmdbId, String title, File sourceFile) async {
    await directoryService.ensureMovieDirectory(tmdbId);
    final path = await pathService.getMovieVideoPath(tmdbId, title);
    final file = File(path);
    return sourceFile.copy(file.path);
  }

  /// Save movie poster
  Future<File> saveMoviePoster(int tmdbId, File sourceFile) async {
    await directoryService.ensureMovieDirectory(tmdbId);
    final path = await pathService.getMoviePosterPath(tmdbId);
    return sourceFile.copy(path);
  }

  /// Save movie backdrop
  Future<File> saveMovieBackdrop(int tmdbId, File sourceFile) async {
    await directoryService.ensureMovieDirectory(tmdbId);
    final path = await pathService.getMovieBackdropPath(tmdbId);
    return sourceFile.copy(path);
  }

  /// Save series poster
  Future<File> saveSeriesPoster(int seriesId, File sourceFile) async {
    await directoryService.ensureSeriesDirectory(seriesId);
    final path = await pathService.getSeriesPosterPath(seriesId);
    return sourceFile.copy(path);
  }

  /// Save series backdrop
  Future<File> saveSeriesBackdrop(int seriesId, File sourceFile) async {
    await directoryService.ensureSeriesDirectory(seriesId);
    final path = await pathService.getSeriesBackdropPath(seriesId);
    return sourceFile.copy(path);
  }

  /// Save episode video
  Future<File> saveEpisodeVideo(
    String title,
    int seriesId,
    int seasonNumber,
    int episodeNumber,
    File sourceFile,
  ) async {
    await directoryService.ensureEpisodeDirectory(
      seriesId,
      seasonNumber,
      episodeNumber,
    );
    final path = await pathService.getEpisodeVideoPath(
      title,
      seriesId,
      seasonNumber,
      episodeNumber,
    );
    final file = File(path);
    return sourceFile.copy(file.path);
  }
}
