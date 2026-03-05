import 'package:path/path.dart';
import 'package:krate/services/storage_service.dart';

class PathService {
  final StorageService storageService;
  String? _cachedRoot;

  PathService(this.storageService);

  Future<String> _root() async {
    if (_cachedRoot != null) return _cachedRoot!;
    final root = await storageService.getRootDirectory();
    if (root == null) throw Exception("Storage root not set");
    _cachedRoot = root;
    return root;
  }
  /// Root folders
  Future<String> getMoviesRoot() async {
    return join(await _root(), "movies");
  }

  Future<String> getSeriesRoot() async {
    return join(await _root(), "series");
  }

  /// Movie paths
  Future<String> getMovieFolder(int tmdbId) async {
    return join(await getMoviesRoot(), "$tmdbId");
  }

  Future<String> getMovieVideoPath(int tmdbId, String title) async {
    return join(await getMovieFolder(tmdbId), "$title.mp4");
  }

  Future<String> getMoviePosterPath(int tmdbId) async {
    return join(await getMovieFolder(tmdbId), ".poster.jpg");
  }

  Future<String> getMovieBackdropPath(int tmdbId) async {
    return join(await getMovieFolder(tmdbId), ".backdrop.jpg");
  }

  /// Series paths
  Future<String> getSeriesFolder(int tmdbId) async {
    return join(await getSeriesRoot(), "$tmdbId");
  }

  Future<String> getSeriesPosterPath(int tmdbId) async {
    return join(await getSeriesFolder(tmdbId), ".poster.jpg");
  }

  Future<String> getSeriesBackdropPath(int tmdbId) async {
    return join(await getSeriesFolder(tmdbId), ".backdrop.jpg");
  }

  /// Season paths
  Future<String> getSeasonFolder(int seriesId, int seasonNumber) async {
    return join(await getSeriesFolder(seriesId), "season_$seasonNumber");
  }

  /// Episode paths
  Future<String> getEpisodeFolder(
    int seriesId,
    int seasonNumber,
    int episodeNumber,
  ) async {
    return join(
      await getSeasonFolder(seriesId, seasonNumber),
      "episode_$episodeNumber",
    );
  }

  Future<String> getEpisodeVideoPath(
    String title,
    int seriesId,
    int seasonNumber,
    int episodeNumber,
  ) async {
    return join(
      await getEpisodeFolder(seriesId, seasonNumber, episodeNumber),
      "${title}_S${seasonNumber.toString().padLeft(2, '0')}E${episodeNumber.toString().padLeft(2, '0')}.mp4"
    );
  }
}
