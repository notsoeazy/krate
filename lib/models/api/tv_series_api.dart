class TvSeriesApi {
  final int id;
  final String name;
  final String? originalName;
  final String? originalLanguage;
  final String? overview;
  final List<String> genres;
  final DateTime? firstAirDate;
  final int numberOfSeasons;
  final int numberOfEpisodes;
  final String? posterPath;
  final String? backdropPath;

  TvSeriesApi({
    required this.id,
    required this.name,
    this.originalName,
    this.originalLanguage,
    this.overview,
    required this.genres,
    this.firstAirDate,
    required this.numberOfSeasons,
    required this.numberOfEpisodes,
    this.posterPath,
    this.backdropPath,
  });

  factory TvSeriesApi.fromMap(Map<String, dynamic> map) {
    return TvSeriesApi(
      id: map['id'],
      name: map['name'] ?? '',
      originalName: map['original_name'],
      originalLanguage: map['original_language'],
      overview: map['overview'],
      genres:
          (map['genres'] as List?)?.map((g) => g['name'] as String).toList() ??
          [],
      firstAirDate:
          map['first_air_date'] != null &&
              map['first_air_date'].toString().isNotEmpty
          ? DateTime.tryParse(map['first_air_date'])
          : null,
      numberOfSeasons: map['number_of_seasons'] ?? 0,
      numberOfEpisodes: map['number_of_episodes'] ?? 0,
      posterPath: map['poster_path'],
      backdropPath: map['backdrop_path'],
    );
  }
}
