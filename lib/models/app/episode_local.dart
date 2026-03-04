class Episode {
  final int? id;
  final int contentId;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String? description;
  final String localVideoPath;
  final int? duration;
  final DateTime? airDate;

  Episode({
    this.id,
    required this.contentId,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    this.description,
    required this.localVideoPath,
    this.duration,
    this.airDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'contentId': contentId,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'title': title,
      'description': description,
      'localVideoPath': localVideoPath,
      'duration': duration,
      'airDate': airDate?.toIso8601String(),
    };
  }

  factory Episode.fromMap(Map<String, dynamic> map) {
    return Episode(
      id: map['id'] as int?,
      contentId: map['contentId'] as int,
      seasonNumber: map['seasonNumber'] as int,
      episodeNumber: map['episodeNumber'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      localVideoPath: map['localVideoPath'] as String,
      duration: map['duration'] != null ? map['duration'] as int : null,
      airDate: map['airDate'] != null ? DateTime.parse(map['airDate']) : null,
    );
  }

  factory Episode.fromApi({
    required int contentId,
    required int seasonNumber,
    required int episodeNumber,
    required String title,
    String? description,
    String? localVideoPath,
    int? duration,
    DateTime? airDate,
  }) {
    return Episode(
      contentId: contentId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      title: title,
      description: description,
      localVideoPath: localVideoPath ?? '',
      duration: duration,
      airDate: airDate,
    );
  }

  Episode copyWith({
    int? id,
    int? contentId,
    int? seasonNumber,
    int? episodeNumber,
    String? title,
    String? description,
    String? localVideoPath,
    int? duration,
    DateTime? airDate,
  }) {
    return Episode(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      localVideoPath: localVideoPath ?? this.localVideoPath,
      duration: duration ?? this.duration,
      airDate: airDate ?? this.airDate,
    );
  }
}
