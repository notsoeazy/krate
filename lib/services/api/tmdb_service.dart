import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:krate/services/api/api_service.dart';

class TMDBService {
  final ApiService _apiService = ApiService();
  final String _baseUrl = "https://api.themoviedb.org/3";

  String get _apiKey => dotenv.env['TMDB_API_KEY'] ?? '';

  Future<List<Map<String, dynamic>>> searchMovies(String query) async {
    final url = "$_baseUrl/search/movie?api_key=$_apiKey&query=$query";
    return await _apiService.getRequestList(url);
  }

  Future<List<Map<String, dynamic>>> searchSeries(String query) async {
    final url = "$_baseUrl/search/tv?api_key=$_apiKey&query=$query";
    return await _apiService.getRequestList(url);
  }

  Future<Map<String, dynamic>> getMovieDetails(int tmdbId) async {
    final url = "$_baseUrl/movie/$tmdbId?api_key=$_apiKey";
    return await _apiService.getRequest(url);
  }

  Future<Map<String, dynamic>> getSeriesDetails(int tmdbId) async {
    final url = "$_baseUrl/tv/$tmdbId?api_key=$_apiKey";
    return await _apiService.getRequest(url);
  }

  Future<Map<String, dynamic>> getSeasonDetails(
    int tmdbId,
    int seasonNumber,
  ) async {
    final url = "$_baseUrl/tv/$tmdbId/season/$seasonNumber?api_key=$_apiKey";
    return await _apiService.getRequest(url);
  }

  Future<List<Map<String, dynamic>>> searchMulti(String query) async {
    final url = "$_baseUrl/search/multi?api_key=$_apiKey&query=$query";
    return await _apiService.getRequestList(url);
  }
  
  // String getPosterUrl(String path) => "https://image.tmdb.org/t/p/w500$path";

  // String getBackdropUrl(String path) => "https://image.tmdb.org/t/p/w780$path";
}
