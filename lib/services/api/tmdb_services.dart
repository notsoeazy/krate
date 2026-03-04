import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'api_service.dart';
import '../../models/app/content.dart';
import '../../models/app/episode_local.dart';
import '../../repository/content_repository.dart';
import '../../repository/episodes_repository.dart';

class TMDBService {
  final ApiService _apiService = ApiService();
  final ContentRepository _contentRepo;
  final EpisodesRepository _episodesRepo;
  final String _baseUrl = "https://api.themoviedb.org/3";

  TMDBService(this._contentRepo, this._episodesRepo);

  String get _apiKey => dotenv.env['TMDB_API_KEY'] ?? '';

  /// Search movies and map to Content
  Future<List<Content>> searchMovies(String query) async {
    final url = "$_baseUrl/search/movie?api_key=$_apiKey&query=$query";
    final results = await _apiService.getRequestList(url);
    return results.map((map) => _mapMovieToContent(map)).toList();
  }

  /// Search series and map to Content (episodes fetched via details)
  Future<List<Content>> searchSeries(String query) async {
    final url = "$_baseUrl/search/tv?api_key=$_apiKey&query=$query";
    final results = await _apiService.getRequestList(url);
    return results.map((map) => _mapSeriesToContent(map)).toList();
  }

  /// Fetch movie from TMDB and save locally
  Future<Content> fetchAndSaveMovie(int tmdbId) async {
    // Check local DB first
    final existingContent = await _contentRepo.getContentByTmdbId(tmdbId);
    if (existingContent != null) return existingContent;

    // Fetch from TMDB
    final url = "$_baseUrl/movie/$tmdbId?api_key=$_apiKey";
    final data = await _apiService.getRequest(url);
    final content = _mapMovieToContent(data);

    // Save locally
    final localId = await _contentRepo.insertContent(content);
    return content.copyWith(id: localId);
  }

  /// Fetch series with episodes from TMDB and save locally
  /// Returns a map: {'content': Content, 'episodes': List<Episode>}
  Future<Map<String, dynamic>> fetchAndSaveSeries(int tmdbId) async {
    // Check local DB first
    final existingContent = await _contentRepo.getContentByTmdbId(tmdbId);
    if (existingContent != null) {
      final episodes = await _episodesRepo.getEpisodesByContentId(
        existingContent.id!,
      );
      return {'content': existingContent, 'episodes': episodes};
    }

    // Fetch series details
    final url = "$_baseUrl/tv/$tmdbId?api_key=$_apiKey";
    final data = await _apiService.getRequest(url);
    final content = _mapSeriesToContent(data, tmdbId: tmdbId);

    // Insert content locally
    final localContentId = await _contentRepo.insertContent(content);
    final savedContent = content.copyWith(id: localContentId);

    List<Episode> savedEpisodes = [];

    // Fetch and insert episodes
    final seasons = data['seasons'] as List<dynamic>?;

    if (seasons != null) {
      for (var season in seasons) {
        final seasonNumber = season['season_number']?.toInt() ?? 0;
        if (seasonNumber <= 0) continue; // Skip specials or invalid seasons

        final seasonUrl =
            "$_baseUrl/tv/$tmdbId/season/$seasonNumber?api_key=$_apiKey";
        final seasonData = await _apiService.getRequest(seasonUrl);
        final episodesData = seasonData['episodes'] as List<dynamic>?;

        if (episodesData != null) {
          for (var ep in episodesData) {
            final episode = Episode.fromApi(
              contentId: localContentId,
              seasonNumber: seasonNumber,
              episodeNumber: ep['episode_number']?.toInt() ?? 1,
              title:
                  ep['name']?.toString() ??
                  'Episode ${ep['episode_number'] ?? 1}',
              description: ep['overview']?.toString(),
              duration: ep['runtime']?.toInt(),
              airDate: ep['air_date'] != null && ep['air_date'] != ''
                  ? DateTime.tryParse(ep['air_date'])
                  : null,
              localVideoPath: '',
            );
            final epId = await _episodesRepo.insertEpisode(episode);
            savedEpisodes.add(episode.copyWith(id: epId));
          }
        }
      }
    }

    return {'content': savedContent, 'episodes': savedEpisodes};
  }

  /// Get movie details by TMDB ID (existing method)
  Future<Content> getMovieDetails(int tmdbId) async {
    final url = "$_baseUrl/movie/$tmdbId?api_key=$_apiKey";
    final data = await _apiService.getRequest(url);
    return _mapMovieToContent(data);
  }

  /// Get series details + all episodes (existing method)
  Future<Map<String, dynamic>> getSeriesDetailsWithEpisodes(int tmdbId) async {
    final url = "$_baseUrl/tv/$tmdbId?api_key=$_apiKey";
    final data = await _apiService.getRequest(url);

    final content = _mapSeriesToContent(data, tmdbId: tmdbId);

    List<Episode> episodes = [];

    final seasons = data['seasons'] as List<dynamic>?;

    if (seasons != null) {
      for (var season in seasons) {
        final seasonNumber = season['season_number']?.toInt() ?? 0;
        if (seasonNumber <= 0) continue;

        final seasonUrl =
            "$_baseUrl/tv/$tmdbId/season/$seasonNumber?api_key=$_apiKey";
        final seasonData = await _apiService.getRequest(seasonUrl);

        final episodesData = seasonData['episodes'] as List<dynamic>?;

        if (episodesData != null) {
          for (var ep in episodesData) {
            episodes.add(
              Episode.fromApi(
                contentId: content.tmdbId ?? tmdbId,
                seasonNumber: seasonNumber,
                episodeNumber: ep['episode_number']?.toInt() ?? 1,
                title:
                    ep['name']?.toString() ??
                    'Episode ${ep['episode_number'] ?? 1}',
                description: ep['overview']?.toString(),
                duration: ep['runtime']?.toInt(),
                airDate: ep['air_date'] != null && ep['air_date'] != ''
                    ? DateTime.tryParse(ep['air_date'])
                    : null,
                localVideoPath: '',
              ),
            );
          }
        }
      }
    }

    return {'content': content, 'episodes': episodes};
  }

  /// Map TMDB movie data to Content
  Content _mapMovieToContent(Map<String, dynamic> map) {
    return Content.fromApi(
      tmdbId: map['id']?.toInt(),
      type: 'movie',
      title: map['title']?.toString() ?? 'Unknown Title',
      description: map['overview']?.toString() ?? '',
      releaseDate: map['release_date'] != null && map['release_date'] != ''
          ? DateTime.tryParse(map['release_date'])
          : null,
      genres: map['genres'] != null
          ? List<String>.from(
              (map['genres'] as List).map((g) => g['name'].toString()),
            )
          : null,
      posterPath: map['poster_path'] != null
          ? getPosterUrl(map['poster_path'])
          : null,
      backdropPath: map['backdrop_path'] != null
          ? getPosterUrl(map['backdrop_path'])
          : null,
      totalSeasons: null,
      totalEpisodes: null,
    );
  }

  /// Map TMDB series data to Content
  Content _mapSeriesToContent(Map<String, dynamic> map, {int? tmdbId}) {
    return Content.fromApi(
      tmdbId: tmdbId ?? map['id']?.toInt(),
      type: 'series',
      title: map['name']?.toString() ?? 'Unknown Title',
      description: map['overview']?.toString() ?? '',
      releaseDate: map['first_air_date'] != null && map['first_air_date'] != ''
          ? DateTime.tryParse(map['first_air_date'])
          : null,
      genres: map['genres'] != null
          ? List<String>.from(
              (map['genres'] as List).map((g) => g['name'].toString()),
            )
          : null,
      posterPath: map['poster_path'] != null
          ? getPosterUrl(map['poster_path'])
          : null,
      backdropPath: map['backdrop_path'] != null
          ? getPosterUrl(map['backdrop_path'])
          : null,
      totalSeasons: map['number_of_seasons']?.toInt(),
      totalEpisodes: map['number_of_episodes']?.toInt(),
    );
  }

  /// Full poster URL
  String getPosterUrl(String path) => "https://image.tmdb.org/t/p/w500$path";
}
