import 'dart:convert';
import 'package:krate/utils/constants.dart';

/// Represents a single piece of media content (movie or series).
///
/// This is an immutable value object. Use [copyWith] to produce modified copies.
class Content {
  final int? id;
  final int? tmdbId;
  final ContentType contentType;
  final String title;
  final String? originalTitle;
  final String? originalLanguage;
  final String? tagline;
  final String? description;
  final List<String>? genres;
  final DateTime? releaseDate;

  /// Runtime in minutes. For series, this is the average episode runtime.
  final int? runtime;

  // Series-specific counts
  final int totalSeasons;
  final int totalEpisodes;

  final double voteAverage;
  final int voteCount;
  final String? tmdbStatus; // e.g. 'Released', 'Ended', 'Returning Series'

  /// TMDB relative poster path (e.g. "/abcdef.jpg"). Retained for future re-download.
  final String? tmdbPosterPath;

  /// TMDB relative backdrop path. Retained for future re-download.
  final String? tmdbBackdropPath;

  /// Absolute local path to the poster file inside the pod.
  final String? localPosterPath;

  /// Absolute local path to the backdrop file inside the pod.
  final String? localBackdropPath;

  /// Absolute path to this content's pod directory on disk.
  final String? podPath;

  final bool isFavorite;
  final FileStatus fileStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Content({
    this.id,
    this.tmdbId,
    required this.contentType,
    required this.title,
    this.originalTitle,
    this.originalLanguage,
    this.tagline,
    this.description,
    this.genres,
    this.releaseDate,
    this.runtime,
    this.totalSeasons = 0,
    this.totalEpisodes = 0,
    this.voteAverage = 0.0,
    this.voteCount = 0,
    this.tmdbStatus,
    this.tmdbPosterPath,
    this.tmdbBackdropPath,
    this.localPosterPath,
    this.localBackdropPath,
    this.podPath,
    this.isFavorite = false,
    this.fileStatus = FileStatus.missing,
    required this.createdAt,
    required this.updatedAt,
  });

  // ---------------------------------------------------------------------------
  // DB serialisation
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toMap() => {
    'tmdbId': tmdbId,
    'contentType': contentType.name,
    'title': title,
    'originalTitle': originalTitle,
    'originalLanguage': originalLanguage,
    'tagline': tagline,
    'description': description,
    'genres': genres != null ? jsonEncode(genres) : null,
    'releaseDate': releaseDate?.toIso8601String(),
    'runtime': runtime,
    'totalSeasons': totalSeasons,
    'totalEpisodes': totalEpisodes,
    'voteAverage': voteAverage,
    'voteCount': voteCount,
    'tmdbStatus': tmdbStatus,
    'tmdbPosterPath': tmdbPosterPath,
    'tmdbBackdropPath': tmdbBackdropPath,
    'localPosterPath': localPosterPath,
    'localBackdropPath': localBackdropPath,
    'podPath': podPath,
    'isFavorite': isFavorite ? 1 : 0,
    'fileStatus': fileStatus.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Content.fromMap(Map<String, dynamic> map) {
    return Content(
      id: map['id'] as int?,
      tmdbId: map['tmdbId'] as int?,
      contentType: ContentType.values.firstWhere(
        (e) => e.name == map['contentType'],
        orElse: () => ContentType.movie,
      ),
      title: map['title'] as String,
      originalTitle: map['originalTitle'] as String?,
      originalLanguage: map['originalLanguage'] as String?,
      tagline: map['tagline'] as String?,
      description: map['description'] as String?,
      genres: map['genres'] != null
          ? List<String>.from(jsonDecode(map['genres'] as String))
          : null,
      releaseDate: map['releaseDate'] != null
          ? DateTime.tryParse(map['releaseDate'] as String)
          : null,
      runtime: map['runtime'] as int?,
      totalSeasons: (map['totalSeasons'] as int?) ?? 0,
      totalEpisodes: (map['totalEpisodes'] as int?) ?? 0,
      voteAverage: (map['voteAverage'] as num?)?.toDouble() ?? 0.0,
      voteCount: (map['voteCount'] as int?) ?? 0,
      tmdbStatus: map['tmdbStatus'] as String?,
      tmdbPosterPath: map['tmdbPosterPath'] as String?,
      tmdbBackdropPath: map['tmdbBackdropPath'] as String?,
      localPosterPath: map['localPosterPath'] as String?,
      localBackdropPath: map['localBackdropPath'] as String?,
      podPath: map['podPath'] as String?,
      isFavorite: map['isFavorite'] == 1,
      fileStatus: FileStatus.values.firstWhere(
        (e) => e.name == (map['fileStatus'] as String?),
        orElse: () => FileStatus.missing,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // ---------------------------------------------------------------------------
  // Factory constructors from TMDB API maps
  // ---------------------------------------------------------------------------

  factory Content.fromTmdbMovie(Map<String, dynamic> data) {
    final now = DateTime.now();
    final genres = (data['genres'] as List?)
        ?.map((g) => g['name'] as String)
        .toList();
    return Content(
      tmdbId: data['id'] as int?,
      contentType: ContentType.movie,
      title: data['title'] as String? ?? 'Unknown',
      originalTitle: data['original_title'] as String?,
      originalLanguage: data['original_language'] as String?,
      tagline: data['tagline'] as String?,
      description: data['overview'] as String?,
      genres: genres,
      releaseDate: data['release_date'] != null
          ? DateTime.tryParse(data['release_date'] as String)
          : null,
      runtime: data['runtime'] as int?,
      voteAverage: (data['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: (data['vote_count'] as int?) ?? 0,
      tmdbStatus: data['status'] as String?,
      tmdbPosterPath: data['poster_path'] as String?,
      tmdbBackdropPath: data['backdrop_path'] as String?,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Content.fromTmdbSeries(Map<String, dynamic> data) {
    final now = DateTime.now();
    final genres = (data['genres'] as List?)
        ?.map((g) => g['name'] as String)
        .toList();
    final runtimes = data['episode_run_time'] as List?;
    return Content(
      tmdbId: data['id'] as int?,
      contentType: ContentType.series,
      title: data['name'] as String? ?? 'Unknown',
      originalTitle: data['original_name'] as String?,
      originalLanguage: data['original_language'] as String?,
      tagline: data['tagline'] as String?,
      description: data['overview'] as String?,
      genres: genres,
      releaseDate: data['first_air_date'] != null
          ? DateTime.tryParse(data['first_air_date'] as String)
          : null,
      runtime: (runtimes != null && runtimes.isNotEmpty)
          ? runtimes.first as int?
          : null,
      totalSeasons: (data['number_of_seasons'] as int?) ?? 0,
      totalEpisodes: (data['number_of_episodes'] as int?) ?? 0,
      voteAverage: (data['vote_average'] as num?)?.toDouble() ?? 0.0,
      voteCount: (data['vote_count'] as int?) ?? 0,
      tmdbStatus: data['status'] as String?,
      tmdbPosterPath: data['poster_path'] as String?,
      tmdbBackdropPath: data['backdrop_path'] as String?,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// True when this content should display a "ghost" (file missing) badge.
  /// A ghost is shown only when ALL associated episodes are missing their files.
  bool get isGhost => fileStatus == FileStatus.missing;

  Content copyWith({
    int? id,
    int? tmdbId,
    ContentType? contentType,
    String? title,
    String? originalTitle,
    String? originalLanguage,
    String? tagline,
    String? description,
    List<String>? genres,
    DateTime? releaseDate,
    int? runtime,
    int? totalSeasons,
    int? totalEpisodes,
    double? voteAverage,
    int? voteCount,
    String? tmdbStatus,
    String? tmdbPosterPath,
    String? tmdbBackdropPath,
    String? localPosterPath,
    String? localBackdropPath,
    String? podPath,
    bool? isFavorite,
    FileStatus? fileStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Content(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      contentType: contentType ?? this.contentType,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      tagline: tagline ?? this.tagline,
      description: description ?? this.description,
      genres: genres ?? this.genres,
      releaseDate: releaseDate ?? this.releaseDate,
      runtime: runtime ?? this.runtime,
      totalSeasons: totalSeasons ?? this.totalSeasons,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      voteAverage: voteAverage ?? this.voteAverage,
      voteCount: voteCount ?? this.voteCount,
      tmdbStatus: tmdbStatus ?? this.tmdbStatus,
      tmdbPosterPath: tmdbPosterPath ?? this.tmdbPosterPath,
      tmdbBackdropPath: tmdbBackdropPath ?? this.tmdbBackdropPath,
      localPosterPath: localPosterPath ?? this.localPosterPath,
      localBackdropPath: localBackdropPath ?? this.localBackdropPath,
      podPath: podPath ?? this.podPath,
      isFavorite: isFavorite ?? this.isFavorite,
      fileStatus: fileStatus ?? this.fileStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
