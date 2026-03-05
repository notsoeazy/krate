import 'package:krate/constants.dart';
import 'package:krate/models/api/episode_api.dart';

class Episode {
  final int? id;
  final int contentId;
  final int seasonNumber;
  final int episodeNumber;
  final String? title;
  final String? description;
  final String? videoPath;
  final int? duration;
  final DateTime? airDate;
  final StatusType status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Episode({
    this.id,
    required this.contentId,
    required this.seasonNumber,
    required this.episodeNumber,
    this.title,
    this.description,
    this.videoPath,
    this.duration,
    this.airDate,
    this.status = StatusType.uninitialized,
    required this.createdAt,
    required this.updatedAt,
  });

  // Used for inserting into database
  Map<String, dynamic> toMap() {
    return {
      'contentId': contentId,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'title': title,
      'description': description,
      'videoPath': videoPath,
      'duration': duration ?? 0,
      'airDate': airDate?.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Used for getting from database
  factory Episode.fromMap(Map<String, dynamic> map) {
    return Episode(
      id: map['id'] as int?,
      contentId: map['contentId'] as int,
      seasonNumber: map['seasonNumber'] as int,
      episodeNumber: map['episodeNumber'] as int,
      title: map['title'] as String?,
      description: map['description'] as String?,
      videoPath: map['videoPath'] as String?,
      duration: map['duration'] != null ? map['duration'] as int : 0,
      airDate: map['airDate'] != null ? DateTime.parse(map['airDate']) : null,
      status: map['status'] != null
          ? StatusType.values.firstWhere(
              (e) => e.name == map['status'],
              orElse: () => StatusType.uninitialized,
            )
          : StatusType.uninitialized,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  factory Episode.fromApi(EpisodeApi api, int contentId) {
    final now = DateTime.now();

    return Episode(
      contentId: contentId,
      seasonNumber: api.seasonNumber,
      episodeNumber: api.episodeNumber,
      title: api.name,
      description: api.overview,
      videoPath: null,
      duration: api.runtime ?? 0,
      airDate: api.airDate,
      status: StatusType.pending,
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
    String? videoPath,
    int? duration,
    DateTime? airDate,
    StatusType? status,
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
      videoPath: videoPath ?? this.videoPath,
      duration: duration ?? this.duration,
      airDate: airDate ?? this.airDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
