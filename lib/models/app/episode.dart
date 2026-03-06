import 'package:krate/constants.dart';
import 'package:krate/models/api/episode_api.dart';

class Episode {
  final int? id;
  final int contentId;
  final int? seasonNumber; // null for movies
  final int? episodeNumber; // null for movies
  final String? title;
  final String? description;
  final int? runtime; // minutes
  final DateTime? airDate;
  final String? videoPath; // absolute local path to video file
  final String? subtitlePath; // path to external .srt / .ass file
  final int subtitleDelay; // ms offset, file-specific
  final StatusType status;
  final bool hasFile; // true if media file exists in the pod
  final DateTime createdAt;
  final DateTime updatedAt;

  Episode({
    this.id,
    required this.contentId,
    this.seasonNumber,
    this.episodeNumber,
    this.title,
    this.description,
    this.runtime,
    this.airDate,
    this.videoPath,
    this.subtitlePath,
    this.subtitleDelay = 0,
    this.status = StatusType.uninitialized,
    this.hasFile = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Used for inserting into the database
  Map<String, dynamic> toMap() {
    return {
      'contentId': contentId,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'title': title,
      'description': description,
      'runtime': runtime,
      'airDate': airDate?.toIso8601String(),
      'videoPath': videoPath,
      'subtitlePath': subtitlePath,
      'subtitleDelay': subtitleDelay,
      'status': status.name,
      'hasFile': hasFile ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Used for reading from the database
  factory Episode.fromMap(Map<String, dynamic> map) {
    return Episode(
      id: map['id'] as int?,
      contentId: map['contentId'] as int,
      seasonNumber: map['seasonNumber'] as int?,
      episodeNumber: map['episodeNumber'] as int?,
      title: map['title'] as String?,
      description: map['description'] as String?,
      runtime: map['runtime'] as int?,
      airDate: map['airDate'] != null
          ? DateTime.tryParse(map['airDate'])
          : null,
      videoPath: map['videoPath'] as String?,
      subtitlePath: map['subtitlePath'] as String?,
      subtitleDelay: (map['subtitleDelay'] as int?) ?? 0,
      status: map['status'] != null
          ? StatusType.values.firstWhere(
              (e) => e.name == map['status'],
              orElse: () => StatusType.uninitialized,
            )
          : StatusType.uninitialized,
      hasFile: map['hasFile'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Used for building from a TMDB episode details response (series only)
  factory Episode.fromApi(EpisodeApi api, int contentId) {
    final now = DateTime.now();
    return Episode(
      contentId: contentId,
      seasonNumber: api.seasonNumber,
      episodeNumber: api.episodeNumber,
      title: api.name,
      description: api.overview,
      runtime: api.runtime,
      airDate: api.airDate,
      videoPath: null,
      subtitlePath: null,
      subtitleDelay: 0,
      status: StatusType.pending,
      hasFile: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Convenience constructor for movie episodes (no season/episode numbers)
  factory Episode.forMovie({
    required int contentId,
    String? videoPath,
    int? runtime,
  }) {
    final now = DateTime.now();
    return Episode(
      contentId: contentId,
      seasonNumber: null,
      episodeNumber: null,
      videoPath: videoPath,
      runtime: runtime,
      status: videoPath != null ? StatusType.ready : StatusType.pending,
      hasFile: videoPath != null,
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
    int? runtime,
    DateTime? airDate,
    String? videoPath,
    String? subtitlePath,
    int? subtitleDelay,
    StatusType? status,
    bool? hasFile,
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
      runtime: runtime ?? this.runtime,
      airDate: airDate ?? this.airDate,
      videoPath: videoPath ?? this.videoPath,
      subtitlePath: subtitlePath ?? this.subtitlePath,
      subtitleDelay: subtitleDelay ?? this.subtitleDelay,
      status: status ?? this.status,
      hasFile: hasFile ?? this.hasFile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
