class Episode {
  final int episodeNumber;
  final String name;
  final String overview;
  final DateTime? airDate;

  Episode({
    required this.episodeNumber,
    required this.name,
    required this.overview,
    required this.airDate,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      episodeNumber: json['episode_number'],
      name: json['name'],
      overview: json['overview'] ?? '',
      airDate: json['air_date'] != null && json['air_date'] != ''
          ? DateTime.parse(json['air_date'])
          : null,
    );
  }
}
