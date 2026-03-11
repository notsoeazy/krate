import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/utils/errors.dart';
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

/// Callback used to report job progress updates.
typedef OnJobUpdate = void Function(ImportJob job);

/// Orchestrates all Krate data operations:
/// - **Scouting**: fetch TMDB metadata, download artwork, scribe DB + metadata (requires internet)
/// - **Linking**: pick local media files and move them into the Vault (offline-capable)
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

  // Scouting downloads TMDB metadata & artwork (requires internet)
  Future<void> scoutMovie({
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
      final podPath = await _storageService.ensurePodDir(content);
      onUpdate(job.copyWith(currentStep: 'Moving file...', progress: 0.1));

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

      onUpdate(
        job.copyWith(currentStep: 'Downloading artwork...', progress: 0.7),
      );
      final artwork = await _artworkService.downloadArtwork(
        tmdbPosterPath: content.tmdbPosterPath,
        tmdbBackdropPath: content.tmdbBackdropPath,
        podPath: podPath,
      );

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

  // Movie Rescan
  Future<void> rescanMovie({
    required Content content,
    required OnJobUpdate onUpdate,
  }) async {
    if (content.tmdbId == null) throw const TmdbIdRequiredException();
    if (!await _hasInternet()) throw const NoInternetException();
    if (content.podPath == null) return;

    final job = ImportJob(
      id: const Uuid().v4(),
      title: 'Rescanning ${content.title}',
      contentType: ContentType.movie,
      status: ImportJobStatus.running,
      startedAt: DateTime.now(),
    );

    onUpdate(
      job.copyWith(currentStep: 'Fetching latest data...', progress: 0.0),
    );

    try {
      final movieData = await _tmdbService.getMovieDetails(content.tmdbId!);

      onUpdate(
        job.copyWith(currentStep: 'Downloading artwork...', progress: 0.2),
      );
      final artwork = await _artworkService.downloadArtwork(
        tmdbPosterPath: movieData['poster_path'] as String?,
        tmdbBackdropPath: movieData['backdrop_path'] as String?,
        podPath: content.podPath!,
        overwrite: true,
      );

      final updatedContent = Content.fromTmdbMovie(movieData).copyWith(
        id: content.id,
        localPosterPath: artwork.posterPath,
        localBackdropPath: artwork.backdropPath,
        podPath: content.podPath,
        fileStatus: content.fileStatus,
        updatedAt: DateTime.now(),
      );
      await _contentRepo.update(updatedContent);

      // Update the single movie episode metadata as well
      final existingEp = await _episodeRepo.getMovieEpisode(content.id!);
      if (existingEp != null) {
        await _episodeRepo.update(
          existingEp.copyWith(runtime: updatedContent.runtime),
        );
      }

      onUpdate(
        job.copyWith(currentStep: 'Scribing metadata...', progress: 0.8),
      );
      await _syncContentMetadata(content.id!);

      onUpdate(
        job.copyWith(
          status: ImportJobStatus.done,
          progress: 1.0,
          currentStep: 'Done',
        ),
      );
    } catch (e, st) {
      debugPrint('[ImportService] Movie rescan failed: $e\n$st');
      onUpdate(
        job.copyWith(status: ImportJobStatus.error, error: e.toString()),
      );
      rethrow;
    }
  }

  // Series scouting
  Future<void> scoutSeries({
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
        fileStatus: FileStatus.missing,
      );

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

      onUpdate(
        job.copyWith(currentStep: 'Registering episodes...', progress: 0.1),
      );
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
            final existingEp = await _episodeRepo.getSeriesEpisode(
              contentId,
              s,
              epNum,
            );
            if (existingEp == null) {
              await _episodeRepo.insert(
                Episode.fromTmdbEpisode(epData, contentId),
              );
            } else {
              await _episodeRepo.update(
                Episode.fromTmdbEpisode(epData, contentId).copyWith(
                  id: existingEp.id,
                  videoPath: existingEp.videoPath,
                  fileStatus: existingEp.fileStatus,
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('[ImportService] Error pre-populating season $s: $e');
        }
      }

      final totalFiles = episodeFiles.values.fold<int>(
        0,
        (sum, m) => sum + m.length,
      );
      int filesDone = 0;

      for (final seasonEntry in episodeFiles.entries) {
        final season = seasonEntry.key;
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

          final existingEp = await _episodeRepo.getSeriesEpisode(
            contentId,
            season,
            epNum,
          );
          if (existingEp != null) {
            await _episodeRepo.update(
              existingEp.copyWith(
                videoPath: destPath,
                fileStatus: FileStatus.ready,
              ),
            );
          }
        }
      }

      await _syncContentMetadata(contentId);

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

  // Rescan refreshes TMDB metadata for existing content (requires internet)
  // Updates an already-scouted series with the latest TMDB metadata.
  // Preserves existing videoPath and fileStatus per episode.
  // Throws NoInternetException when offline.
  Future<void> rescanSeries({
    required Content content,
    required OnJobUpdate onUpdate,
  }) async {
    if (content.tmdbId == null) throw const TmdbIdRequiredException();
    if (!await _hasInternet()) throw const NoInternetException();
    if (content.podPath == null) return;

    final job = ImportJob(
      id: const Uuid().v4(),
      title: 'Rescanning ${content.title}',
      contentType: ContentType.series,
      status: ImportJobStatus.running,
      startedAt: DateTime.now(),
    );

    onUpdate(
      job.copyWith(currentStep: 'Fetching latest data...', progress: 0.0),
    );

    try {
      final seriesData = await _tmdbService.getSeriesDetails(content.tmdbId!);

      onUpdate(
        job.copyWith(currentStep: 'Downloading artwork...', progress: 0.1),
      );
      final artwork = await _artworkService.downloadArtwork(
        tmdbPosterPath: seriesData['poster_path'] as String?,
        tmdbBackdropPath: seriesData['backdrop_path'] as String?,
        podPath: content.podPath!,
        overwrite: true,
      );

      final updatedContent = Content.fromTmdbSeries(seriesData).copyWith(
        id: content.id,
        localPosterPath: artwork.posterPath,
        localBackdropPath: artwork.backdropPath,
        podPath: content.podPath,
        fileStatus: content.fileStatus,
        updatedAt: DateTime.now(),
      );
      await _contentRepo.update(updatedContent);

      onUpdate(
        job.copyWith(currentStep: 'Updating episodes...', progress: 0.3),
      );

      int processedSeasons = 0;
      for (int s = 1; s <= updatedContent.totalSeasons; s++) {
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
              content.id!,
              s,
              epNum,
            );
            final updated = Episode.fromTmdbEpisode(epData, content.id!);
            if (existing == null) {
              await _episodeRepo.insert(updated);
            } else {
              // Preserve file linking data
              await _episodeRepo.update(
                updated.copyWith(
                  id: existing.id,
                  videoPath: existing.videoPath,
                  fileStatus: existing.fileStatus,
                ),
              );
            }
          }
        } catch (e) {
          debugPrint('[ImportService] Rescan: error fetching season $s: $e');
        }
        processedSeasons++;
        onUpdate(
          job.copyWith(
            currentStep: 'Season $s updated',
            progress:
                0.3 + (processedSeasons / updatedContent.totalSeasons) * 0.6,
          ),
        );
      }

      onUpdate(
        job.copyWith(currentStep: 'Scribing metadata...', progress: 0.95),
      );
      await _syncContentMetadata(content.id!);

      onUpdate(
        job.copyWith(
          status: ImportJobStatus.done,
          progress: 1.0,
          currentStep: 'Done',
        ),
      );
    } catch (e, st) {
      debugPrint('[ImportService] Rescan failed: $e\n$st');
      onUpdate(
        job.copyWith(status: ImportJobStatus.error, error: e.toString()),
      );
      rethrow;
    }
  }

  // Linking moves local media into the Vault (offline-capable)
  // Links (moves) multiple local media files to existing series episodes.
  Future<void> linkEpisodes({
    required Content content,
    required Map<int, String> episodeFiles, // episodeId -> filePath
    required OnJobUpdate onUpdate,
  }) async {
    if (content.podPath == null) return;

    final job = ImportJob(
      id: const Uuid().v4(),
      title: 'Linking files for ${content.title}',
      contentType: ContentType.series,
      status: ImportJobStatus.running,
      startedAt: DateTime.now(),
    );

    onUpdate(job.copyWith(currentStep: 'Preparing...', progress: 0.0));

    try {
      final podPath = content.podPath!;
      final totalFiles = episodeFiles.length;
      int filesDone = 0;

      for (final entry in episodeFiles.entries) {
        final episodeId = entry.key;
        final srcPath = entry.value;

        final episode = await _episodeRepo.getById(episodeId);
        if (episode == null) continue;

        final destPath = episode.isMovie
            ? await _storageService.movieFilePath(content, podPath, srcPath)
            : await _storageService.episodeFilePath(
                content,
                podPath,
                episode.seasonNumber ?? 1,
                episode.episodeNumber ?? 1,
                srcPath,
              );

        onUpdate(
          job.copyWith(
            currentStep:
                'Linking S${(episode.seasonNumber ?? 0).toString().padLeft(2, '0')}E${(episode.episodeNumber ?? 0).toString().padLeft(2, '0')}...',
            progress: (filesDone / totalFiles) * 0.9,
          ),
        );

        await _moveFile(srcPath, destPath);
        await _episodeRepo.update(
          episode.copyWith(videoPath: destPath, fileStatus: FileStatus.ready),
        );
        filesDone++;
      }

      onUpdate(
        job.copyWith(currentStep: 'Scribing metadata...', progress: 0.95),
      );
      await _syncContentMetadata(content.id!);

      final allEpisodes = await _episodeRepo.getByContentId(content.id!);
      await _metadataService.scribe(
        content: (await _contentRepo.getById(content.id!)) ?? content,
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
      debugPrint('[ImportService] Link failed: $e\n$st');
      onUpdate(
        job.copyWith(status: ImportJobStatus.error, error: e.toString()),
      );
    }
  }

  // Re-links (replaces) a single episode's media file.
  Future<void> relinkEpisode({
    required Content content,
    required Episode episode,
    required String sourceFilePath,
  }) async {
    if (content.podPath == null || episode.id == null) return;

    final podPath = content.podPath!;
    final destPath = episode.isMovie
        ? await _storageService.movieFilePath(content, podPath, sourceFilePath)
        : await _storageService.episodeFilePath(
            content,
            podPath,
            episode.seasonNumber!,
            episode.episodeNumber!,
            sourceFilePath,
          );

    await _moveFile(sourceFilePath, destPath);

    final oldPath = episode.videoPath;
    await _episodeRepo.update(
      episode.copyWith(videoPath: destPath, fileStatus: FileStatus.ready),
    );

    if (oldPath != null && oldPath != destPath) {
      final f = File(oldPath);
      if (await f.exists()) await f.delete();
    }

    await _syncContentMetadata(content.id!);

    final allEps = await _episodeRepo.getByContentId(content.id!);
    await _metadataService.scribe(
      content: (await _contentRepo.getById(content.id!)) ?? content,
      episodes: allEps,
      podPath: podPath,
    );
  }

  // Deletion
  Future<void> deleteContent(
    Content content, {
    bool deleteFiles = false,
  }) async {
    if (content.id == null) return;
    if (deleteFiles && content.podPath != null) {
      final dir = Directory(content.podPath!);
      if (await dir.exists()) await dir.delete(recursive: true);
    }
    await _contentRepo.delete(content.id!);
  }

  Future<void> deleteEpisodeFile({
    required Content content,
    required Episode episode,
  }) async {
    // Always update the DB/scribe — even if the file is already gone from disk.
    if (episode.videoPath != null) {
      final file = File(episode.videoPath!);
      if (await file.exists()) await file.delete();
    }
    await _episodeRepo.update(
      episode.copyWith(clearVideoPath: true, fileStatus: FileStatus.missing),
    );

    if (content.podPath != null) {
      await _syncContentMetadata(content.id!);
      final allEps = await _episodeRepo.getByContentId(content.id!);
      await _metadataService.scribe(
        content: (await _contentRepo.getById(content.id!)) ?? content,
        episodes: allEps,
        podPath: content.podPath!,
      );
    }
  }

  Future<void> deleteEpisodesBatch({
    required Content content,
    required List<Episode> episodes,
  }) async {
    for (final ep in episodes) {
      // Always clear the DB record for every selected episode.
      if (ep.videoPath != null) {
        final file = File(ep.videoPath!);
        if (await file.exists()) await file.delete();
      }
      await _episodeRepo.update(
        ep.copyWith(clearVideoPath: true, fileStatus: FileStatus.missing),
      );
    }

    if (content.podPath != null) {
      await _syncContentMetadata(content.id!);
      final allEps = await _episodeRepo.getByContentId(content.id!);

      await _metadataService.scribe(
        content: (await _contentRepo.getById(content.id!)) ?? content,
        episodes: allEps,
        podPath: content.podPath!,
      );
    }
  }

  // Internal Helpers
  // Returns true if the device can reach the internet.
  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('api.themoviedb.org');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Ensures parent Content's metadata (fileStatus, average runtime) stays in sync with its episodes
  Future<void> _syncContentMetadata(int contentId) async {
    final episodes = await _episodeRepo.getByContentId(contentId);
    final anyReady = episodes.any((e) => e.fileStatus == FileStatus.ready);
    final isReady = anyReady ? FileStatus.ready : FileStatus.missing;

    final content = await _contentRepo.getById(contentId);
    if (content == null) return;

    int? avgRuntime;
    if (content.contentType == ContentType.series) {
      final runtimes = episodes
          .map((e) => e.runtime)
          .where((r) => r != null && r > 0)
          .cast<int>()
          .toList();

      if (runtimes.isNotEmpty) {
        avgRuntime = (runtimes.reduce((a, b) => a + b) / runtimes.length)
            .round();
      }
    } else {
      avgRuntime = content.runtime;
    }

    final updated = content.copyWith(fileStatus: isReady, runtime: avgRuntime);

    if (content.fileStatus != isReady || content.runtime != avgRuntime) {
      await _contentRepo.update(updated);

      // Re-scribe metadata if podPath exists
      if (content.podPath != null) {
        await _metadataService.scribe(
          content: updated,
          episodes: episodes,
          podPath: content.podPath!,
        );
      }
    }
  }

  Future<void> _moveFile(
    String src,
    String dest, {
    void Function(double)? onProgress,
  }) async {
    final source = File(src);
    if (!await source.exists()) throw SourceFileMissingException(src);
    final destination = File(dest);
    await destination.parent.create(recursive: true);

    try {
      if (await destination.exists()) await destination.delete();
      await source.rename(dest);
      onProgress?.call(1.0);
      return;
    } catch (_) {}

    await _copyWithProgress(source, destination, onProgress);
    final isCacheFile =
        src.contains('/cache/') ||
        src.contains('/tmp/') ||
        src.contains('com.android.providers.downloads.documents');
    if (isCacheFile) await source.delete();
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
