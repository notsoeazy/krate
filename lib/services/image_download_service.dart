import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:krate/services/path_service.dart';

class ImageDownloadService {
  final PathService pathService;

  static const String _baseUrl = "https://image.tmdb.org/t/p/";

  ImageDownloadService(this.pathService);

  /// Build full TMDB image URL
  String _buildUrl(String size, String path) {
    return "$_baseUrl$size$path";
  }

  /// Generic image downloader
  Future<void> _downloadImage(String url, String savePath) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception("Failed to download image: $url");
    }

    final file = File(savePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(response.bodyBytes);
  }

  /// Download movie poster
  Future<void> downloadMoviePoster(int tmdbId, String posterPath) async {
    final url = _buildUrl("w500", posterPath);
    final savePath = await pathService.getMoviePosterPath(tmdbId);

    await _downloadImage(url, savePath);
  }

  /// Download movie backdrop
  Future<void> downloadMovieBackdrop(int tmdbId, String backdropPath) async {
    final url = _buildUrl("w780", backdropPath);
    final savePath = await pathService.getMovieBackdropPath(tmdbId);

    await _downloadImage(url, savePath);
  }

  /// Download series poster
  Future<void> downloadSeriesPoster(int tmdbId, String posterPath) async {
    final url = _buildUrl("w500", posterPath);
    final savePath = await pathService.getSeriesPosterPath(tmdbId);

    await _downloadImage(url, savePath);
  }

  /// Download series backdrop
  Future<void> downloadSeriesBackdrop(int tmdbId, String backdropPath) async {
    final url = _buildUrl("w780", backdropPath);
    final savePath = await pathService.getSeriesBackdropPath(tmdbId);

    await _downloadImage(url, savePath);
  }
}
