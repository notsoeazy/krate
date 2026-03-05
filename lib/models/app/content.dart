import 'dart:convert';
import 'package:krate/constants.dart';

import 'package:krate/models/api/movie_api.dart';
import 'package:krate/models/api/tv_series_api.dart';

class Content {
  final int? id;
  final int? tmdbId;
  final ContentType contentType; // movie | series | anime
  final String title;
  final String? originalTitle;
  final String? originalLanguage;
  final String? description;
  final List<String>? genres;
  final DateTime? releaseDate;
  final String? posterPath;
  final String? backdropPath;
  final String? localPosterPath;
  final String? localBackdropPath;
  final String? videoPath;
  final int? duration;
  final int? totalSeasons;
  final int? totalEpisodes;
  final bool isFavorite;
  final StatusType status; // uninitialized | pending | ready | failed
  final DateTime createdAt;
  final DateTime updatedAt;

  Content({
    this.id,
    this.tmdbId,
    required this.contentType,
    required this.title,
    this.originalTitle,
    this.originalLanguage,
    this.description,
    this.genres,
    this.releaseDate,
    this.posterPath,
    this.backdropPath,
    this.localPosterPath,
    this.localBackdropPath,
    this.videoPath,
    this.duration,
    this.totalSeasons,
    this.totalEpisodes,
    required this.isFavorite,
    this.status = StatusType.uninitialized,
    required this.createdAt,
    required this.updatedAt,
  });

  // Used for inserting to database
  Map<String, dynamic> toMap() {
    return {
      'tmdbId': tmdbId,
      'contentType': contentType.name,
      'title': title,
      'originalTitle': originalTitle,
      'originalLanguage': originalLanguage,
      'description': description,
      'genres': genres != null ? jsonEncode(genres) : null,
      'releaseDate': releaseDate?.toIso8601String(),
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'localPosterPath': localPosterPath,
      'localBackdropPath': localBackdropPath,
      'videoPath': videoPath,
      'duration': duration,
      'totalSeasons': totalSeasons ?? 0,
      'totalEpisodes': totalEpisodes ?? 0,
      'isFavorite': isFavorite ? 1 : 0,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Used for getting from database
  factory Content.fromMap(Map<String, dynamic> map) {
    return Content(
      id: map['id'] as int?,
      tmdbId: map['tmdbId'] as int?,
      contentType: map['contentType'] != null
          ? ContentType.values.firstWhere(
              (e) => e.name == map['contentType'],
              orElse: () => ContentType.movie,
            )
          : ContentType.movie,
      title: map['title'] as String,
      originalTitle: map['originalTitle'] as String?,
      originalLanguage: map['originalLanguage'] as String?,
      description: map['description'] as String?,
      genres: map['genres'] != null
          ? List<String>.from(jsonDecode(map['genres']))
          : null,
      releaseDate: map['releaseDate'] != null
          ? DateTime.parse(map['releaseDate'])
          : null,
      posterPath: map['posterPath'] as String?,
      backdropPath: map['backdropPath'] as String?,
      localPosterPath: map['localPosterPath'] as String?,
      localBackdropPath: map['localBackdropPath'] as String?,
      videoPath: map['videoPath'] as String?,
      duration: map['duration'] as int?,
      totalSeasons: map['totalSeasons'] != null
          ? map['totalSeasons'] as int
          : 0,
      totalEpisodes: map['totalEpisodes'] != null
          ? map['totalEpisodes'] as int
          : 0,
      isFavorite: map['isFavorite'] == 1,
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

  // Used for getting from API
  factory Content.fromMovieApi(MovieApi api) {
    final now = DateTime.now();

    return Content(
      tmdbId: api.id,
      contentType: ContentType.movie,
      title: api.title,
      originalTitle: api.originalTitle,
      originalLanguage: api.originalLanguage,
      description: api.overview,
      genres: api.genres,
      releaseDate: api.releaseDate,
      posterPath: api.posterPath,
      backdropPath: api.backdropPath,
      localPosterPath: null,
      localBackdropPath: null,
      videoPath: null,
      duration: api.runtime,
      totalSeasons: 0,
      totalEpisodes: 0,
      isFavorite: false,
      status: StatusType.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Content.fromSeriesApi(TvSeriesApi api) {
    final now = DateTime.now();

    return Content(
      tmdbId: api.id,
      contentType: ContentType.series,
      title: api.name,
      originalTitle: api.originalName,
      originalLanguage: api.originalLanguage,
      description: api.overview,
      genres: api.genres,
      releaseDate: api.firstAirDate,
      posterPath: api.posterPath,
      backdropPath: api.backdropPath,
      localPosterPath: null,
      localBackdropPath: null,
      videoPath: null,
      duration: null,
      totalSeasons: api.numberOfSeasons,
      totalEpisodes: api.numberOfEpisodes,
      isFavorite: false,
      status: StatusType.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Copy with updated fields
  Content copyWith({
    int? id,
    int? tmdbId,
    ContentType? contentType,
    String? title,
    String? originalTitle,
    String? originalLanguage,
    String? description,
    List<String>? genres,
    DateTime? releaseDate,
    String? posterPath,
    String? backdropPath,
    String? localPosterPath,
    String? localBackdropPath,
    String? videoPath,
    int? duration,
    int? totalSeasons,
    int? totalEpisodes,
    bool? isFavorite,
    StatusType? status,
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
      description: description ?? this.description,
      genres: genres ?? this.genres,
      releaseDate: releaseDate ?? this.releaseDate,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      localPosterPath: localPosterPath ?? this.localPosterPath,
      localBackdropPath: localBackdropPath ?? this.localBackdropPath,
      videoPath: videoPath ?? this.videoPath,
      duration: duration ?? this.duration,
      totalSeasons: totalSeasons ?? this.totalSeasons,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      isFavorite: isFavorite ?? this.isFavorite,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
