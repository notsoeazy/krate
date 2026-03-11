import 'dart:convert';
import 'dart:io';
import 'package:krate/utils/constants.dart';
import 'package:krate/utils/errors.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/data/models/episode.dart';
import 'package:path/path.dart' as p;

// Handles reading and writing the .metadata.json scribe file.
// The scribe is the source of truth — if the SQLite DB is ever lost,
// the entire library can be rebuilt by scanning for these files.
class MetadataService {
  // Writes (scribes) all content metadata to <podPath>/.metadata.json.
  // All TMDB paths are preserved so that artwork can be re-downloaded later.
  // All episode video paths are stored as relative paths for portability.
  Future<void> scribe({
    required Content content,
    required List<Episode> episodes,
    required String podPath,
  }) async {
    final isMovie = content.contentType == ContentType.movie;

    final data = <String, dynamic>{
      'version': kMetadataSchemaVersion,
      'type': content.contentType.name,
      'tmdbId': content.tmdbId,
      'title': content.title,
      'originalTitle': content.originalTitle,
      'originalLanguage': content.originalLanguage,
      'tagline': content.tagline,
      'overview': content.description,
      'genres': content.genres,
      'releaseDate': content.releaseDate?.toIso8601String(),
      'runtime': content.runtime,
      'voteAverage': content.voteAverage,
      'voteCount': content.voteCount,
      'tmdbStatus': content.tmdbStatus,
      // Retain TMDB remote paths so artwork can be re-downloaded
      'tmdbPosterPath': content.tmdbPosterPath,
      'tmdbBackdropPath': content.tmdbBackdropPath,
      // Standardised local names — always relative
      'posterPath': kPosterFileName,
      'backdropPath': kBackdropFileName,
      'fileStatus': content.fileStatus.name,
    };

    if (!isMovie) {
      data['totalSeasons'] = content.totalSeasons;
      data['totalEpisodes'] = content.totalEpisodes;
      data['episodes'] = episodes.map((e) {
        return {
          'season': e.seasonNumber,
          'episode': e.episodeNumber,
          'title': e.title,
          'overview': e.description,
          'airDate': e.airDate?.toIso8601String(),
          'runtime': e.runtime,
          'videoPath': e.videoPath != null
              ? p.relative(e.videoPath!, from: podPath)
              : null,
          'fileStatus': e.fileStatus.name,
        };
      }).toList();
    } else if (episodes.isNotEmpty && episodes.first.videoPath != null) {
      data['videoPath'] = p.relative(episodes.first.videoPath!, from: podPath);
    }

    final file = File(p.join(podPath, kMetadataFileName));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }

  // Reads a .metadata.json file and returns reconstructed [Content] and
  // [Episode] objects with absolute paths. The [contentId] is a placeholder
  // (-1) since the DB has not been consulted yet.
  Future<({Content content, List<Episode> episodes})> read(
    String metadataFilePath,
  ) async {
    final file = File(metadataFilePath);
    if (!await file.exists()) {
      throw MetadataParseException(metadataFilePath);
    }

    late Map<String, dynamic> data;
    try {
      data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      throw MetadataParseException(metadataFilePath);
    }

    final podPath = p.dirname(metadataFilePath);
    final now = DateTime.now();
    final contentType = ContentType.values.firstWhere(
      (e) => e.name == (data['type'] as String?),
      orElse: () => ContentType.movie,
    );

    final content = Content(
      tmdbId: data['tmdbId'] as int?,
      contentType: contentType,
      title: data['title'] as String? ?? 'Unknown',
      originalTitle: data['originalTitle'] as String?,
      originalLanguage: data['originalLanguage'] as String?,
      tagline: data['tagline'] as String?,
      description: data['overview'] as String?,
      genres: data['genres'] != null
          ? List<String>.from(data['genres'] as List)
          : null,
      releaseDate: data['releaseDate'] != null
          ? DateTime.tryParse(data['releaseDate'] as String)
          : null,
      runtime: data['runtime'] as int?,
      totalSeasons: (data['totalSeasons'] as int?) ?? 0,
      totalEpisodes: (data['totalEpisodes'] as int?) ?? 0,
      voteAverage: (data['voteAverage'] as num?)?.toDouble() ?? 0.0,
      voteCount: (data['voteCount'] as int?) ?? 0,
      tmdbStatus: data['tmdbStatus'] as String?,
      tmdbPosterPath: data['tmdbPosterPath'] as String?,
      tmdbBackdropPath: data['tmdbBackdropPath'] as String?,
      localPosterPath: data['posterPath'] != null
          ? p.join(podPath, data['posterPath'] as String)
          : null,
      localBackdropPath: data['backdropPath'] != null
          ? p.join(podPath, data['backdropPath'] as String)
          : null,
      podPath: podPath,
      fileStatus: FileStatus.values.firstWhere(
        (e) => e.name == (data['fileStatus'] as String?),
        orElse: () => FileStatus.missing,
      ),
      createdAt: now,
      updatedAt: now,
    );

    final episodes = <Episode>[];

    if (contentType == ContentType.movie) {
      final relPath = data['videoPath'] as String?;
      final absPath = relPath != null ? p.join(podPath, relPath) : null;
      episodes.add(
        Episode(
          contentId: -1,
          videoPath: absPath,
          runtime: data['runtime'] as int?,
          fileStatus: absPath != null ? FileStatus.ready : FileStatus.missing,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else if (data['episodes'] != null) {
      for (final ep in data['episodes'] as List) {
        final epMap = ep as Map<String, dynamic>;
        final relPath = epMap['videoPath'] as String?;
        final absPath = relPath != null ? p.join(podPath, relPath) : null;
        episodes.add(
          Episode(
            contentId: -1,
            seasonNumber: epMap['season'] as int?,
            episodeNumber: epMap['episode'] as int?,
            title: epMap['title'] as String?,
            description: epMap['overview'] as String?,
            airDate: epMap['airDate'] != null
                ? DateTime.tryParse(epMap['airDate'] as String)
                : null,
            runtime: epMap['runtime'] as int?,
            videoPath: absPath,
            fileStatus: FileStatus.values.firstWhere(
              (e) => e.name == (epMap['fileStatus'] as String?),
              orElse: () => FileStatus.missing,
            ),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    return (content: content, episodes: episodes);
  }
}
