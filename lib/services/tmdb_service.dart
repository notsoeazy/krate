import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:krate/utils/errors.dart';

class TMDBService {
  static const _base = 'https://api.themoviedb.org/3';

  String get _apiKey => dotenv.env['TMDB_API_KEY'] ?? '';

  // Search
  Future<List<Map<String, dynamic>>> searchMulti(String query) async {
    final results = await _getList(
      '$_base/search/multi?api_key=$_apiKey&query=${Uri.encodeComponent(query)}',
    );
    // Filter to only movie/tv media types
    return results
        .where((r) => r['media_type'] == 'movie' || r['media_type'] == 'tv')
        .toList();
  }

  Future<List<Map<String, dynamic>>> searchMovies(String query) => _getList(
    '$_base/search/movie?api_key=$_apiKey&query=${Uri.encodeComponent(query)}',
  );

  Future<List<Map<String, dynamic>>> searchSeries(String query) => _getList(
    '$_base/search/tv?api_key=$_apiKey&query=${Uri.encodeComponent(query)}',
  );

  // Details
  Future<Map<String, dynamic>> getMovieDetails(int tmdbId) =>
      _get('$_base/movie/$tmdbId?api_key=$_apiKey&append_to_response=credits');

  Future<Map<String, dynamic>> getSeriesDetails(int tmdbId) =>
      _get('$_base/tv/$tmdbId?api_key=$_apiKey');

  Future<Map<String, dynamic>> getSeasonDetails(int tmdbId, int seasonNumber) =>
      _get('$_base/tv/$tmdbId/season/$seasonNumber?api_key=$_apiKey');

  // Image URL helpers
  static String posterUrl(String tmdbPath, {String size = 'w500'}) =>
      'https://image.tmdb.org/t/p/$size$tmdbPath';

  static String backdropUrl(String tmdbPath, {String size = 'w780'}) =>
      'https://image.tmdb.org/t/p/$size$tmdbPath';

  // Private HTTP helpers
  Future<Map<String, dynamic>> _get(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw TmdbApiException('HTTP ${response.statusCode} for $url');
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TmdbApiException {
      rethrow;
    } catch (e) {
      throw TmdbApiException('$e');
    }
  }

  Future<List<Map<String, dynamic>>> _getList(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw TmdbApiException('HTTP ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final results = body['results'] as List? ?? [];
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[TMDBService] Error: $e');
      return [];
    }
  }
}
