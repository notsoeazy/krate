class MovieApi {
  final int id;
  final String title;
  final String? originalTitle;
  final String? originalLanguage;
  final String? overview;
  final List<String> genres;
  final DateTime? releaseDate;
  final int? runtime;
  final String? posterPath;
  final String? backdropPath;

  MovieApi({
    required this.id,
    required this.title,
    this.originalTitle,
    this.originalLanguage,
    this.overview,
    required this.genres,
    this.releaseDate,
    this.runtime,
    this.posterPath,
    this.backdropPath,
  });

  factory MovieApi.fromMap(Map<String, dynamic> map) {
    return MovieApi(
      id: map['id'] as int,
      title: map['title'] ?? '',
      originalTitle: map['original_title'],
      originalLanguage: map['original_language'],
      overview: map['overview'],
      genres: _parseGenres(map),
      releaseDate: _parseDate(map['release_date']),
      runtime: map['runtime'],
      posterPath: map['poster_path'],
      backdropPath: map['backdrop_path'],
    );
  }

  static List<String> _parseGenres(Map<String, dynamic> map) {
    if (map['genres'] != null && map['genres'] is List) {
      return List<Map<String, dynamic>>.from(
        map['genres'],
      ).map((genre) => genre['name'] as String).toList();
    }
    return [];
  }

  static DateTime? _parseDate(String? date) {
    if (date == null || date.isEmpty) return null;
    return DateTime.tryParse(date);
  }
}
