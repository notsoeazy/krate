import './genre.dart';
import './season.dart';

class TVSeries {
  final int id;
  final String name;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final DateTime? firstAirDate;
  final List<Genre> genres;
  final List<Season> seasons;
  final double voteAverage;

  TVSeries({
    required this.id,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.firstAirDate,
    required this.genres,
    required this.seasons,
    required this.voteAverage,
  });

  factory TVSeries.fromJson(Map<String, dynamic> json) {
    return TVSeries(
      id: json['id'],
      name: json['name'],
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      firstAirDate:
          json['first_air_date'] != null && json['first_air_date'] != ''
          ? DateTime.parse(json['first_air_date'])
          : null,
      genres: (json['genres'] as List<dynamic>)
          .map((e) => Genre.fromJson(e))
          .toList(),
      seasons: (json['seasons'] as List<dynamic>)
          .map((e) => Season.fromJson(e))
          .toList(),
      voteAverage: (json['vote_average'] as num).toDouble(),
    );
  }
}
