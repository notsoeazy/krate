import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:krate/core/constants.dart';
import 'package:krate/core/errors.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/data/models/import_job.dart';
import 'package:krate/data/repositories/content_repository.dart';
import 'package:krate/data/repositories/episode_repository.dart';
import 'package:krate/services/artwork_service.dart';
import 'package:krate/services/metadata_service.dart';
import 'package:krate/services/storage_service.dart';
import 'package:krate/services/tmdb_service.dart';
import 'package:uuid/uuid.dart';

/// Callback used to report import progress updates.
typedef OnJobUpdate = void Function(ImportJob job);

/// Orchestrates the full "Scribe" import flow.
///
/// Each import is independent — multiple movies or episodes can be imported
/// concurrently. Progress is reported via the [OnJobUpdate] callback, which
/// the Riverpod [ImportJobsNotifier] wires up.
class ImportService {
  final ContentRepository _contentRepo;
  final EpisodeRepository _episodeRepo;
  final ArtworkService _artworkService;
  final MetadataService _metadataService;
  final StorageService _storageService;
  final TMDBService _tmdbService;

  ImportService({
    required ContentRepository contentRepo,
    required EpisodeRepository episodeRepo,
    required ArtworkService artworkService,
    required MetadataService metadataService,
    required StorageService storageService,
    required TMDBService tmdbService,
  }) : _contentRepo = contentRepo,
       _episodeRepo = episodeRepo,
       _artworkService = artworkService,
       _metadataService = metadataService,
       _storageService = storageService,
       _tmdbService = tmdbService;

  // ---------------------------------------------------------------------------
  // Movie import
  // ---------------------------------------------------------------------------

  Future<void> importMovie({
    required Content content,
    required String sourceFilePath,
    required OnJobUpdate onUpdate,
  }) async {
    if (content.tmdbId == null) throw const TmdbIdRequiredException();

    final job = ImportJob(
      id: const Uuid().v4(),
      title: content.title,
      contentType: ContentType.movie,
      status: ImportJobStatus.running,
      startedAt: DateTime.now(),
    );

    onUpdate(job.copyWith(currentStep: 'Preparing...', progress: 0.0));

    try {
      // 1. Ensure pod directory
      final podPath = await _storageService.ensurePodDir(content);
      onUpdate(job.copyWith(currentStep: 'Moving file...', progress: 0.1));

      // 2. Move/copy video file
      final destPath = await _storageService.movieFilePath(
        content,
        podPath,
        sourceFilePath,
      );
      await _moveFile(
        sourceFilePath,
        destPath,
        onProgress: (p) => onUpdate(job.copyWith(progress: 0.1 + p * 0.6)),
      );

      // 3. Download artwork
      onUpdate(
        job.copyWith(currentStep: 'Downloading artwork...', progress: 0.7),
      );
      final artwork = await _artworkService.downloadArtwork(
        tmdbPosterPath: content.tmdbPosterPath,
        tmdbBackdropPath: content.tmdbBackdropPath,
        podPath: podPath,
      );

      // 4. Upsert DB records
      onUpdate(
        job.copyWith(currentStep: 'Saving to library...', progress: 0.85),
      );
      final updatedContent = content.copyWith(
        localPosterPath: artwork.posterPath,
        localBackdropPath: artwork.backdropPath,
        podPath: podPath,
        fileStatus: FileStatus.ready,
      );

      final existingContent = await _contentRepo.getByTmdbId(content.tmdbId!);
      final int contentId;
      if (existingContent != null) {
        contentId = existingContent.id!;
        await _contentRepo.update(updatedContent.copyWith(id: contentId));
      } else {
        contentId = await _contentRepo.insert(
          updatedContent.copyWith(id: null),
        );
      }

      final movieEp = Episode.forMovie(
        contentId: contentId,
        videoPath: destPath,
        runtime: content.runtime,
      );
      final existingEp = await _episodeRepo.getMovieEpisode(contentId);
      if (existingEp != null) {
        await _episodeRepo.update(movieEp.copyWith(id: existingEp.id));
      } else {
        await _episodeRepo.insert(movieEp);
      }

      // 5. Scribe metadata.json
      onUpdate(
        job.copyWith(currentStep: 'Scribing metadata...', progress: 0.95),
      );
      await _metadataService.scribe(
        content: updatedContent.copyWith(id: contentId),
        episodes: [movieEp],
        podPath: podPath,
      );

      onUpdate(
        job.copyWith(
          status: ImportJobStatus.done,
          progress: 1.0,
          currentStep: 'Done',
        ),
      );
    } catch (e, st) {
      debugPrint('[ImportService] Movie import failed: $e\n$st');
      onUpdate(
        job.copyWith(status: ImportJobStatus.error, error: e.toString()),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Series import
  // ---------------------------------------------------------------------------

  /// Imports multiple episodes for a series.
  ///
  /// [episodeFiles] maps season → episode → source file path.
  Future<void> importSeries({
    required Content content,
    required Map<int, Map<int, String>> episodeFiles,
    required OnJobUpdate onUpdate,
  }) async {
    if (content.tmdbId == null) throw const TmdbIdRequiredException();

    final job = ImportJob(
      id: const Uuid().v4(),
      title: content.title,
      contentType: ContentType.series,
      status: ImportJobStatus.running,
      startedAt: DateTime.now(),
    );

    onUpdate(job.copyWith(currentStep: 'Preparing...', progress: 0.0));

    try {
      final podPath = await _storageService.ensurePodDir(content);

      // Download artwork first
      onUpdate(
        job.copyWith(currentStep: 'Downloading artwork...', progress: 0.05),
      );
      final artwork = await _artworkService.downloadArtwork(
        tmdbPosterPath: content.tmdbPosterPath,
        tmdbBackdropPath: content.tmdbBackdropPath,
        podPath: podPath,
      );

      final updatedContent = content.copyWith(
        localPosterPath: artwork.posterPath,
        localBackdropPath: artwork.backdropPath,
        podPath: podPath,
        fileStatus: FileStatus.ready,
      );

      // Upsert content record
      final existing = await _contentRepo.getByTmdbId(content.tmdbId!);
      final int contentId;
      if (existing != null) {
        contentId = existing.id!;
        await _contentRepo.update(updatedContent.copyWith(id: contentId));
      } else {
        contentId = await _contentRepo.insert(
          updatedContent.copyWith(id: null),
        );
      }

      // 3. Pre-populate all episodes for all seasons (Offline-first)
      onUpdate(
        job.copyWith(currentStep: 'Registering episodes...', progress: 0.1),
      );
      final List<Episode> allSeasonsEpisodes = [];
      for (int s = 1; s <= content.totalSeasons; s++) {
        try {
          final seasonData = await _tmdbService.getSeasonDetails(
            content.tmdbId!,
            s,
          );
          final epList = (seasonData['episodes'] as List?) ?? [];
          for (final eData in epList) {
            final epData = eData as Map<String, dynamic>;
            final epNum = epData['episode_number'] as int? ?? 0;

            final existing = await _episodeRepo.getSeriesEpisode(
              contentId,
              s,
              epNum,
            );
            if (existing == null) {
              final ep = Episode.fromTmdbEpisode(epData, contentId);
              await _episodeRepo.insert(ep);
              allSeasonsEpisodes.add(ep);
            } else {
              // Update metadata if it changed (cloud side)
              final updated = Episode.fromTmdbEpisode(epData, contentId)
                  .copyWith(
                    id: existing.id,
                    videoPath: existing.videoPath,
                    fileStatus: existing.fileStatus,
                  );
              await _episodeRepo.update(updated);
              allSeasonsEpisodes.add(updated);
            }
          }
        } catch (e) {
          debugPrint('[ImportService] Error pre-populating season $s: $e');
        }
      }

      // 4. Import files
      // Count total files for progress reporting
      final totalFiles = episodeFiles.values.fold<int>(
        0,
        (sum, m) => sum + m.length,
      );
      int filesDone = 0;

      final importedEpisodes = <Episode>[];

      for (final seasonEntry in episodeFiles.entries) {
        final season = seasonEntry.key;

        // Fetch TMDB episode metadata for this season
        Map<int, Map<String, dynamic>> tmdbEpMap = {};
        try {
          final seasonData = await _tmdbService.getSeasonDetails(
            content.tmdbId!,
            season,
          );
          final epList = (seasonData['episodes'] as List?) ?? [];
          for (final e in epList) {
            final ep = e as Map<String, dynamic>;
            final num = ep['episode_number'] as int? ?? 0;
            tmdbEpMap[num] = ep;
          }
        } catch (_) {}

        for (final epEntry in seasonEntry.value.entries) {
          final epNum = epEntry.key;
          final srcPath = epEntry.value;

          final destPath = await _storageService.episodeFilePath(
            content,
            podPath,
            season,
            epNum,
            srcPath,
          );

          await _moveFile(
            srcPath,
            destPath,
            onProgress: (p) {
              if (totalFiles > 0) {
                onUpdate(
                  job.copyWith(
                    currentStep:
                        'Importing S${season.toString().padLeft(2, '0')}E${epNum.toString().padLeft(2, '0')}...',
                    progress: 0.1 + ((filesDone + p) / totalFiles) * 0.8,
                  ),
                );
              }
            },
          );

          filesDone++;

          final tmdbData = tmdbEpMap[epNum];
          final Episode ep;
          if (tmdbData != null) {
            ep = Episode.fromTmdbEpisode(
              tmdbData,
              contentId,
            ).copyWith(videoPath: destPath, fileStatus: FileStatus.ready);
          } else {
            ep = Episode(
              contentId: contentId,
              seasonNumber: season,
              episodeNumber: epNum,
              videoPath: destPath,
              fileStatus: FileStatus.ready,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }

          final existing = await _episodeRepo.getSeriesEpisode(
            contentId,
            season,
            epNum,
          );
          if (existing != null) {
            await _episodeRepo.update(ep.copyWith(id: existing.id));
          } else {
            await _episodeRepo.insert(ep);
          }
          importedEpisodes.add(ep);
        }
      }

      onUpdate(
        job.copyWith(currentStep: 'Scribing metadata...', progress: 0.95),
      );
      final allEpisodes = await _episodeRepo.getByContentId(contentId);
      await _metadataService.scribe(
        content: updatedContent.copyWith(id: contentId),
        episodes: allEpisodes,
        podPath: podPath,
      );

      onUpdate(
        job.copyWith(
          status: ImportJobStatus.done,
          progress: 1.0,
          currentStep: 'Done',
        ),
      );
    } catch (e, st) {
      debugPrint('[ImportService] Series import failed: $e\n$st');
      onUpdate(
        job.copyWith(status: ImportJobStatus.error, error: e.toString()),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // File replacement
  // ---------------------------------------------------------------------------

  /// Replaces the video file for an existing episode, without losing metadata.
  Future<void> replaceEpisodeFile({
    required Content content,
    required Episode episode,
    required String sourceFilePath,
  }) async {
    if (content.podPath == null || episode.id == null) return;

    final destPath = episode.isMovie
        ? await _storageService.movieFilePath(
            content,
            content.podPath!,
            sourceFilePath,
          )
        : await _storageService.episodeFilePath(
            content,
            content.podPath!,
            episode.seasonNumber!,
            episode.episodeNumber!,
            sourceFilePath,
          );

    await _moveFile(sourceFilePath, destPath);

    final oldPath = episode.videoPath;
    final updatedEp = episode.copyWith(
      videoPath: destPath,
      fileStatus: FileStatus.ready,
    );
    await _episodeRepo.update(updatedEp);

    // Delete old file if different
    if (oldPath != null && oldPath != destPath) {
      try {
        final f = File(oldPath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }

    // Re-scribe metadata
    final allEps = await _episodeRepo.getByContentId(content.id!);
    await _metadataService.scribe(
      content: content,
      episodes: allEps,
      podPath: content.podPath!,
    );
  }

  // ---------------------------------------------------------------------------
  // Deletion
  // ---------------------------------------------------------------------------

  /// Deletes library records. If [deleteFiles] is true, also removes the
  /// entire pod folder from disk.
  Future<void> deleteContent(
    Content content, {
    bool deleteFiles = false,
  }) async {
    if (content.id == null) return;

    if (deleteFiles && content.podPath != null) {
      final dir = Directory(content.podPath!);
      if (await dir.exists()) {
        try {
          await dir.delete(recursive: true);
        } catch (_) {}
      }
    }

    await _contentRepo.delete(content.id!);
  }

  // ---------------------------------------------------------------------------
  // File move / copy
  // ---------------------------------------------------------------------------

  Future<void> _moveFile(
    String src,
    String dest, {
    void Function(double)? onProgress,
  }) async {
    final source = File(src);
    if (!await source.exists()) throw SourceFileMissingException(src);

    final destination = File(dest);

    // Ensure destination directory exists
    await destination.parent.create(recursive: true);

    // Try atomic rename first (same filesystem = instant)
    try {
      if (await destination.exists()) await destination.delete();
      await source.rename(dest);
      onProgress?.call(1.0);
      return;
    } catch (_) {
      // Cross-filesystem: fall back to copy + delete
    }

    await _copyWithProgress(source, destination, onProgress);

    // Only delete source if it's in a temporary/cache directory.
    // On Android, file_picker paths often contain '/cache/' or '/tmp/'.
    // This prevents accidental deletion of user originals if they picked from a stable folder.
    final isCacheFile =
        src.contains('/cache/') ||
        src.contains('/tmp/') ||
        src.contains('com.android.providers.downloads.documents');

    if (isCacheFile) {
      await source.delete();
    }
  }

  Future<void> _copyWithProgress(
    File src,
    File dest,
    void Function(double)? onProgress,
  ) async {
    final total = await src.length();
    int copied = 0;
    final reader = src.openRead();
    final writer = dest.openWrite();
    try {
      await for (final chunk in reader) {
        writer.add(chunk);
        copied += chunk.length;
        if (total > 0) onProgress?.call(copied / total);
      }
    } finally {
      await writer.close();
    }
  }
}
