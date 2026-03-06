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
  final String? tagline;
  final String? description;
  final List<String>? genres;
  final DateTime? releaseDate;
  final int? runtime; // minutes
  final int totalSeasons;
  final int totalEpisodes;
  final double voteAverage; // 0.0–10.0
  final int voteCount;
  final String? status; // 'Released' | 'Ended' | 'Returning Series' etc.
  final String? posterPath; // TMDB relative path
  final String? backdropPath; // TMDB relative path
  final String? localPosterPath; // absolute local path
  final String? localBackdropPath; // absolute local path
  final bool isFavorite;
  final bool hasFile; // For movies: true if media file exists
  final DateTime createdAt;
  final DateTime updatedAt;

  Content({
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
    this.voteAverage = 0,
    this.voteCount = 0,
    this.status,
    this.posterPath,
    this.backdropPath,
    this.localPosterPath,
    this.localBackdropPath,
    required this.isFavorite,
    this.hasFile = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Used for inserting into the database
  Map<String, dynamic> toMap() {
    return {
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
      'status': status,
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'localPosterPath': localPosterPath,
      'localBackdropPath': localBackdropPath,
      'isFavorite': isFavorite ? 1 : 0,
      'hasFile': hasFile ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Used for reading from the database
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
      tagline: map['tagline'] as String?,
      description: map['description'] as String?,
      genres: map['genres'] != null
          ? List<String>.from(jsonDecode(map['genres']))
          : null,
      releaseDate: map['releaseDate'] != null
          ? DateTime.tryParse(map['releaseDate'])
          : null,
      runtime: map['runtime'] as int?,
      totalSeasons: (map['totalSeasons'] as int?) ?? 0,
      totalEpisodes: (map['totalEpisodes'] as int?) ?? 0,
      voteAverage: (map['voteAverage'] as num?)?.toDouble() ?? 0.0,
      voteCount: (map['voteCount'] as int?) ?? 0,
      status: map['status'] as String?,
      posterPath: map['posterPath'] as String?,
      backdropPath: map['backdropPath'] as String?,
      localPosterPath: map['localPosterPath'] as String?,
      localBackdropPath: map['localBackdropPath'] as String?,
      isFavorite: map['isFavorite'] == 1,
      hasFile: map['hasFile'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Used for building a Content from a TMDB movie details response
  factory Content.fromMovieApi(MovieApi api) {
    final now = DateTime.now();
    return Content(
      tmdbId: api.id,
      contentType: ContentType.movie,
      title: api.title,
      originalTitle: api.originalTitle,
      originalLanguage: api.originalLanguage,
      tagline: api.tagline,
      description: api.overview,
      genres: api.genres,
      releaseDate: api.releaseDate,
      runtime: api.runtime,
      totalSeasons: 0,
      totalEpisodes: 0,
      voteAverage: api.voteAverage ?? 0.0,
      voteCount: api.voteCount ?? 0,
      status: api.status,
      posterPath: api.posterPath,
      backdropPath: api.backdropPath,
      localPosterPath: null,
      localBackdropPath: null,
      isFavorite: false,
      hasFile: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Used for building a Content from a TMDB TV series details response
  factory Content.fromSeriesApi(TvSeriesApi api) {
    final now = DateTime.now();
    return Content(
      tmdbId: api.id,
      contentType: ContentType.series,
      title: api.name,
      originalTitle: api.originalName,
      originalLanguage: api.originalLanguage,
      tagline: api.tagline,
      description: api.overview,
      genres: api.genres,
      releaseDate: api.firstAirDate,
      runtime: api.episodeRuntime,
      totalSeasons: api.numberOfSeasons,
      totalEpisodes: api.numberOfEpisodes,
      voteAverage: api.voteAverage ?? 0.0,
      voteCount: api.voteCount ?? 0,
      status: api.status,
      posterPath: api.posterPath,
      backdropPath: api.backdropPath,
      localPosterPath: null,
      localBackdropPath: null,
      isFavorite: false,
      hasFile: false,
      createdAt: now,
      updatedAt: now,
    );
  }

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
    String? status,
    String? posterPath,
    String? backdropPath,
    String? localPosterPath,
    String? localBackdropPath,
    bool? isFavorite,
    bool? hasFile,
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
      status: status ?? this.status,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      localPosterPath: localPosterPath ?? this.localPosterPath,
      localBackdropPath: localBackdropPath ?? this.localBackdropPath,
      isFavorite: isFavorite ?? this.isFavorite,
      hasFile: hasFile ?? this.hasFile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
