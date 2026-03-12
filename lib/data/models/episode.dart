import 'package:krate/utils/constants.dart';
import 'package:krate/data/models/subtitle.dart';

class Episode {
  final int? id;
  final int contentId;
  final int? tmdbId;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? title;
  final String? description;
  final int? runtime; // minutes
  final DateTime? airDate;
  final String? videoPath;
  final List<Subtitle> subtitles;
  final FileStatus fileStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Episode({
    this.id,
    required this.contentId,
    this.tmdbId,
    this.seasonNumber,
    this.episodeNumber,
    this.title,
    this.description,
    this.runtime,
    this.airDate,
    this.videoPath,
    this.subtitles = const [],
    this.fileStatus = FileStatus.missing,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructors
  factory Episode.forMovie({
    required int contentId,
    String? videoPath,
    int? runtime,
  }) {
    final now = DateTime.now();
    return Episode(
      contentId: contentId,
      videoPath: videoPath,
      runtime: runtime,
      fileStatus: videoPath != null ? FileStatus.ready : FileStatus.missing,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Episode.fromTmdbEpisode(Map<String, dynamic> data, int contentId) {
    final now = DateTime.now();
    return Episode(
      contentId: contentId,
      seasonNumber: data['season_number'] as int?,
      episodeNumber: data['episode_number'] as int?,
      title: data['name'] as String?,
      description: data['overview'] as String?,
      runtime: data['runtime'] as int?,
      airDate: data['air_date'] != null
          ? DateTime.tryParse(data['air_date'] as String)
          : null,
      fileStatus: FileStatus.missing,
      createdAt: now,
      updatedAt: now,
    );
  }

  // DB serialization
  Map<String, dynamic> toMap() => {
    'contentId': contentId,
    'seasonNumber': seasonNumber,
    'episodeNumber': episodeNumber,
    'title': title,
    'description': description,
    'runtime': runtime,
    'airDate': airDate?.toIso8601String(),
    'videoPath': videoPath,
    'fileStatus': fileStatus.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Episode.fromMap(Map<String, dynamic> map, {List<Subtitle> subtitles = const []}) {
    return Episode(
      id: map['id'] as int?,
      contentId: map['contentId'] as int,
      seasonNumber: map['seasonNumber'] as int?,
      episodeNumber: map['episodeNumber'] as int?,
      title: map['title'] as String?,
      description: map['description'] as String?,
      runtime: map['runtime'] as int?,
      airDate: map['airDate'] != null
          ? DateTime.tryParse(map['airDate'] as String)
          : null,
      videoPath: map['videoPath'] as String?,
      subtitles: subtitles,
      fileStatus: FileStatus.values.firstWhere(
        (e) => e.name == (map['fileStatus'] as String?),
        orElse: () => FileStatus.missing,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Helpers

  bool get isMovie => seasonNumber == null;
  bool get hasFile => fileStatus == FileStatus.ready;

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
    bool clearVideoPath = false,
    List<Subtitle>? subtitles,
    FileStatus? fileStatus,
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
      videoPath: clearVideoPath ? null : (videoPath ?? this.videoPath),
      subtitles: subtitles ?? this.subtitles,
      fileStatus: fileStatus ?? this.fileStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
