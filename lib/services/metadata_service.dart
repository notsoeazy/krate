import 'dart:convert';
import 'dart:io' hide ContentType;
import 'package:krate/constants.dart';
import 'package:krate/models/app/content.dart';
import 'package:krate/models/app/episode.dart';
import 'package:path/path.dart' as p;

/// Handles serialization of media metadata to/from `.metadata.json`.
///
/// This is the core of the "Self-Scribed Library" architecture, allowing
/// the filesystem to be the source of truth for the library.
class MetadataService {
  static const String metadataFileName = '.metadata.json';
  static const int schemaVersion = 1;

  /// Scribes (writes) metadata to a `.metadata.json` file in the given [directoryPath].
  ///
  /// The [content] and [episodes] are converted to a portable JSON format
  /// where all paths are relative to the [directoryPath].
  Future<void> scribeMetadata({
    required Content content,
    required List<Episode> episodes,
    required String directoryPath,
  }) async {
    final Map<String, dynamic> data = {
      'version': schemaVersion,
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
      'status': content.status,
      // Artwork paths are always standardized to hidden files in the pod root
      'posterPath': '.poster.jpg',
      'backdropPath': '.backdrop.jpg',
      'hasFile': content.hasFile,
    };

    if (content.contentType != ContentType.movie) {
      data['totalSeasons'] = content.totalSeasons;
      data['totalEpisodes'] = content.totalEpisodes;
      data['episodes'] = episodes.map((e) {
        // Calculate the relative path for the episode video file
        String? relativeVideoPath;
        if (e.videoPath != null) {
          relativeVideoPath = p.relative(e.videoPath!, from: directoryPath);
        }

        return {
          'season': e.seasonNumber,
          'episode': e.episodeNumber,
          'title': e.title,
          'overview': e.description,
          'airDate': e.airDate?.toIso8601String(),
          'runtime': e.runtime,
          'videoPath': relativeVideoPath,
          'hasFile': e.hasFile,
        };
      }).toList();
    } else if (episodes.isNotEmpty) {
      // For movies, we might still have a single episode object representing the movie file
      final movieEpisode = episodes.first;
      if (movieEpisode.videoPath != null) {
        data['videoPath'] = p.relative(
          movieEpisode.videoPath!,
          from: directoryPath,
        );
      } else {
        data['videoPath'] = null;
      }
    }

    final file = File(p.join(directoryPath, metadataFileName));
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }

  /// Reads metadata from a `.metadata.json` file.
  ///
  /// Returns a Map containing the 'content' object and a list of 'episodes'.
  /// Paths in the returned objects are absolute, converted using the [directoryPath].
  Future<Map<String, dynamic>> readMetadata(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Metadata file not found', filePath);
    }

    final String contentString = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(contentString);
    final String directoryPath = p.dirname(filePath);

    final ContentType contentType = ContentType.values.firstWhere(
      (e) => e.name == data['type'],
      orElse: () => ContentType.movie,
    );

    final now = DateTime.now();

    final Content content = Content(
      tmdbId: data['tmdbId'],
      contentType: contentType,
      title: data['title'] ?? 'Unknown',
      originalTitle: data['originalTitle'],
      originalLanguage: data['originalLanguage'],
      tagline: data['tagline'],
      description: data['overview'],
      genres: data['genres'] != null ? List<String>.from(data['genres']) : null,
      releaseDate: data['releaseDate'] != null
          ? DateTime.tryParse(data['releaseDate'])
          : null,
      runtime: data['runtime'],
      voteAverage: (data['voteAverage'] as num?)?.toDouble() ?? 0.0,
      voteCount: data['voteCount'] ?? 0,
      status: data['status'],
      posterPath:
          data['tmdbPosterPath'], // This field isn't in my scribe, might need to add it if we want it preserved
      backdropPath: data['tmdbBackdropPath'],
      localPosterPath: data['posterPath'] != null
          ? p.join(directoryPath, data['posterPath'])
          : null,
      localBackdropPath: data['backdropPath'] != null
          ? p.join(directoryPath, data['backdropPath'])
          : null,
      isFavorite: false, // UI state, not in metadata.json
      hasFile: data['hasFile'] ?? false,
      createdAt: now,
      updatedAt: now,
    );

    final List<Episode> episodes = [];

    if (contentType == ContentType.movie) {
      if (data['videoPath'] != null) {
        episodes.add(
          Episode.forMovie(
            contentId: -1, // Placeholder
            videoPath: p.join(directoryPath, data['videoPath']),
            runtime: data['runtime'],
          ).copyWith(hasFile: data['hasFile'] ?? true),
        );
      }
    } else if (data['episodes'] != null) {
      for (final episodeData in data['episodes']) {
        String? absoluteVideoPath;
        if (episodeData['videoPath'] != null) {
          absoluteVideoPath = p.join(directoryPath, episodeData['videoPath']);
        }

        episodes.add(
          Episode(
            contentId: -1, // Placeholder
            seasonNumber: episodeData['season'],
            episodeNumber: episodeData['episode'],
            title: episodeData['title'],
            description: episodeData['overview'],
            airDate: episodeData['airDate'] != null
                ? DateTime.tryParse(episodeData['airDate'])
                : null,
            runtime: episodeData['runtime'],
            videoPath: absoluteVideoPath,
            hasFile: episodeData['hasFile'] ?? false,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    }

    return {'content': content, 'episodes': episodes};
  }
}
