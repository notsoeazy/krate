import 'dart:io';
import 'package:krate/services/path_service.dart';

class DirectoryService {
  final PathService pathService;

  DirectoryService(this.pathService);

  /// Ensure a directory exists, create if missing
  Future<Directory> _ensureDir(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Movie folder
  Future<Directory> ensureMovieDirectory(int tmdbId) async {
    final path = await pathService.getMovieFolder(tmdbId);
    return _ensureDir(path);
  }

  /// Series folder
  Future<Directory> ensureSeriesDirectory(int tmdbId) async {
    final path = await pathService.getSeriesFolder(tmdbId);
    return _ensureDir(path);
  }

  /// Season folder
  Future<Directory> ensureSeasonDirectory(
    int seriesId,
    int seasonNumber,
  ) async {
    final path = await pathService.getSeasonFolder(seriesId, seasonNumber);
    return _ensureDir(path);
  }

  /// Episode folder
  Future<Directory> ensureEpisodeDirectory(
    int seriesId,
    int seasonNumber,
    int episodeNumber,
  ) async {
    final path = await pathService.getEpisodeFolder(
      seriesId,
      seasonNumber,
      episodeNumber,
    );
    return _ensureDir(path);
  }
}
