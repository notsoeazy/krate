class TvSeriesApi {
  final int id;
  final String name;
  final String? originalName;
  final String? originalLanguage;
  final String? overview;
  final String? tagline;
  final List<String> genres;
  final DateTime? firstAirDate;
  final int numberOfSeasons;
  final int numberOfEpisodes;
  final int? episodeRuntime; // average episode runtime in minutes
  final double? voteAverage;
  final String? status;
  final String? posterPath;
  final String? backdropPath;
  final int? voteCount;

  TvSeriesApi({
    required this.id,
    required this.name,
    this.originalName,
    this.originalLanguage,
    this.overview,
    this.tagline,
    required this.genres,
    this.firstAirDate,
    required this.numberOfSeasons,
    required this.numberOfEpisodes,
    this.episodeRuntime,
    this.voteAverage,
    this.status,
    this.posterPath,
    this.backdropPath,
    this.voteCount,
  });

  factory TvSeriesApi.fromMap(Map<String, dynamic> map) {
    // TMDB returns episode_run_time as a list — take the first value
    final runtimes = map['episode_run_time'];
    final runtime = (runtimes is List && runtimes.isNotEmpty)
        ? runtimes.first as int?
        : null;

    return TvSeriesApi(
      id: map['id'],
      name: map['name'] ?? '',
      originalName: map['original_name'],
      originalLanguage: map['original_language'],
      overview: map['overview'],
      tagline: map['tagline'],
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
      episodeRuntime: runtime,
      voteAverage: (map['vote_average'] as num?)?.toDouble(),
      status: map['status'],
      posterPath: map['poster_path'],
      backdropPath: map['backdrop_path'],
      voteCount: map['vote_count'],
    );
  }
}
