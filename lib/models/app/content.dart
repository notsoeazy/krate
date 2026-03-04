import 'dart:convert';

class Content {
  final int? id;
  final int? tmdbId;
  final String contentType; // movie | series | anime
  final String title;
  final String description;
  final List<String>? genres;
  final DateTime? releaseDate;
  final String? posterPath;
  final String? backdropPath;
  final String? localImagePath;
  final int? totalSeasons;
  final int? totalEpisodes;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  Content({
    this.id,
    this.tmdbId,
    required this.contentType,
    required this.title,
    required this.description,
    this.genres,
    this.releaseDate,
    this.posterPath,
    this.backdropPath,
    this.localImagePath,
    this.totalSeasons,
    this.totalEpisodes,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Used for INSERT
  Map<String, dynamic> toMap() {
    return {
      'tmdbId': tmdbId,
      'contentType': contentType,
      'title': title,
      'description': description,
      'genres': genres != null ? jsonEncode(genres) : null,
      'releaseDate': releaseDate?.toIso8601String(),
      'posterPath': posterPath,
      'backdropPath': backdropPath,
      'localImagePath': localImagePath,
      'totalSeasons': totalSeasons,
      'totalEpisodes': totalEpisodes,
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Content.fromMap(Map<String, dynamic> map) {
    return Content(
      id: map['id'] as int?,
      tmdbId: map['tmdbId'] as int?,
      contentType: map['contentType'],
      title: map['title'],
      description: map['description'],
      genres: map['genres'] != null
          ? List<String>.from(jsonDecode(map['genres']))
          : null,
      releaseDate: map['releaseDate'] != null
          ? DateTime.parse(map['releaseDate'])
          : null,
      posterPath: map['posterPath'],
      backdropPath: map['backdropPath'],
      localImagePath: map['localImagePath'],
      totalSeasons: map['totalSeasons'],
      totalEpisodes: map['totalEpisodes'],
      isFavorite: map['isFavorite'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Map from API
  factory Content.fromApi({
    required String title,
    required String description,
    required String type,
    List<String>? genres,
    DateTime? releaseDate,
    String? posterPath,
    String? backdropPath,
    int? totalSeasons,
    int? totalEpisodes,
    int? tmdbId,
  }) {
    final now = DateTime.now();

    return Content(
      tmdbId: tmdbId,
      contentType: type,
      title: title,
      description: description,
      genres: genres,
      releaseDate: releaseDate,
      posterPath: posterPath,
      backdropPath: backdropPath,
      localImagePath: posterPath,
      totalSeasons: totalSeasons,
      totalEpisodes: totalEpisodes,
      isFavorite: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  Content copyWith({
    int? id,
    int? tmdbId,
    String? contentType,
    String? title,
    String? description,
    List<String>? genres,
    DateTime? releaseDate,
    String? posterPath,
    String? backdropPath,
    String? localImagePath,
    int? totalSeasons,
    int? totalEpisodes,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Content(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      contentType: contentType ?? this.contentType,
      title: title ?? this.title,
      description: description ?? this.description,
      genres: genres ?? this.genres,
      releaseDate: releaseDate ?? this.releaseDate,
      posterPath: posterPath ?? this.posterPath,
      backdropPath: backdropPath ?? this.backdropPath,
      localImagePath: localImagePath ?? this.localImagePath,
      totalSeasons: totalSeasons ?? this.totalSeasons,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
