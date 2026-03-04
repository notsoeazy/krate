class Season {
  final int seasonNumber;
  final String name;
  final int episodeCount;
  final String? posterPath;

  Season({
    required this.seasonNumber,
    required this.name,
    required this.episodeCount,
    required this.posterPath,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      seasonNumber: json['season_number'],
      name: json['name'],
      episodeCount: json['episode_count'],
      posterPath: json['poster_path'],
    );
  }
}
