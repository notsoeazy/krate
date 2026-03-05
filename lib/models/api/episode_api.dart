class EpisodeApi {
  final int id;
  final int seasonNumber;
  final int episodeNumber;
  final String? name;
  final String? overview;
  final int? runtime;
  final DateTime? airDate;

  EpisodeApi({
    required this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    this.name,
    this.overview,
    this.runtime,
    this.airDate,
  });

  factory EpisodeApi.fromMap(Map<String, dynamic> map) {
    return EpisodeApi(
      id: map['id'],
      seasonNumber: map['season_number'],
      episodeNumber: map['episode_number'],
      name: map['name'],
      overview: map['overview'],
      runtime: map['runtime'],
      airDate: map['air_date'] != null && map['air_date'].toString().isNotEmpty
          ? DateTime.tryParse(map['air_date'])
          : null,
    );
  }
}
