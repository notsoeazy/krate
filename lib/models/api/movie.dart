import './genre.dart';

class Movie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final DateTime? releaseDate;
  final List<Genre> genres;
  final int runtime;
  final double voteAverage;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.genres,
    required this.runtime,
    required this.voteAverage,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      releaseDate: json['release_date'] != null && json['release_date'] != ''
          ? DateTime.parse(json['release_date'])
          : null,
      genres: (json['genres'] as List<dynamic>)
          .map((e) => Genre.fromJson(e))
          .toList(),
      runtime: json['runtime'] ?? 0,
      voteAverage: (json['vote_average'] as num).toDouble(),
    );
  }
}