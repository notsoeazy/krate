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
  final DateTime createdAt;
  final DateTime updatedAt;

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
    required this.createdAt,
    required this.updatedAt,
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
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
    final now = DateTime.now();
    return Episode(
      contentId: contentId,
      seasonNumber: seasonNumber,
      episodeNumber: episodeNumber,
      title: title,
      description: description,
      localVideoPath: localVideoPath ?? '',
      duration: duration,
      airDate: airDate,
      createdAt: now,
      updatedAt: now,
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
    DateTime? createdAt,
    DateTime? updatedAt,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
