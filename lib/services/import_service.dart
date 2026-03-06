import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:krate/models/api/episode_api.dart';
import 'package:krate/models/app/content.dart';
import 'package:krate/models/app/episode.dart';
import 'package:krate/repositories/content_repository.dart';
import 'package:krate/repositories/episode_repository.dart';
import 'package:krate/services/artwork_service.dart';
import 'package:krate/services/api/tmdb_service.dart';
import 'package:krate/services/metadata_service.dart';
import 'package:krate/services/storage_service.dart';
import 'package:krate/utils/title_cleaner.dart';
import 'package:krate/constants.dart';
import 'package:path/path.dart' as p;

/// Coordinates the full import flow into custom storage root.
class ImportService extends ChangeNotifier {
  ContentRepository _contentRepo;
  EpisodeRepository _episodeRepo;
  ArtworkService _artworkService;
  TMDBService _tmdbService;
  MetadataService _metadataService;
  StorageService _storageService;

  bool _isImporting = false;
  bool get isImporting => _isImporting;

  double _progress = 0;
  double get progress => _progress;

  String? _currentTaskTitle;
  String? get currentTaskTitle => _currentTaskTitle;

  ImportService({
    required ContentRepository contentRepo,
    required EpisodeRepository episodeRepo,
    required ArtworkService artworkService,
    required TMDBService tmdbService,
    required MetadataService metadataService,
    required StorageService storageService,
  }) : _contentRepo = contentRepo,
       _episodeRepo = episodeRepo,
       _artworkService = artworkService,
       _tmdbService = tmdbService,
       _metadataService = metadataService,
       _storageService = storageService;

  void updateDependencies({
    required ContentRepository contentRepo,
    required EpisodeRepository episodeRepo,
    required ArtworkService artworkService,
    required TMDBService tmdbService,
    required MetadataService metadataService,
    required StorageService storageService,
  }) {
    _contentRepo = contentRepo;
    _episodeRepo = episodeRepo;
    _artworkService = artworkService;
    _tmdbService = tmdbService;
    _metadataService = metadataService;
    _storageService = storageService;
  }

  void _updateState({bool? isImporting, double? progress, String? title}) {
    if (isImporting != null) _isImporting = isImporting;
    if (progress != null) _progress = progress;
    if (title != null) _currentTaskTitle = title;
    notifyListeners();
  }

  Future<Content> importMovie(
    Content content,
    String sourceFilePath, {
    void Function(double)? onProgress,
  }) async {
    if (_isImporting) throw StateError('An import is already in progress');
    if (content.tmdbId == null) throw ArgumentError('tmdbId required');

    _updateState(isImporting: true, title: content.title, progress: 0);

    try {
      final existingContent = await _contentRepo.getContentByTmdbId(
        content.tmdbId!,
      );
      final contentId =
          existingContent?.id ?? await _contentRepo.insertContent(content);

      if (existingContent != null) {
        await _contentRepo.updateContent(content.copyWith(id: contentId));
      }

      final destPath = await _movieDestPath(content, sourceFilePath);
      final podDir = p.dirname(destPath);

      _updateState(progress: 0.1);

      await _moveFile(
        sourceFilePath,
        destPath,
        onProgress: (p) => _updateState(progress: 0.1 + (p * 0.7)),
      );

      final artwork = await _artworkService.downloadArtwork(
        content: content,
        posterTmdbPath: content.posterPath,
        backdropTmdbPath: content.backdropPath,
        targetDirectory: podDir,
      );

      _updateState(progress: 0.9);

      final updatedContent = content.copyWith(
        id: contentId,
        localPosterPath: artwork.posterPath,
        localBackdropPath: artwork.backdropPath,
        status: StatusType.ready.name,
        hasFile: true,
      );
      await _contentRepo.updateContent(updatedContent);

      final movieEpisode = Episode.forMovie(
        contentId: contentId,
        videoPath: destPath,
        runtime: content.runtime,
      ).copyWith(hasFile: true);

      final episodes = await _episodeRepo.getEpisodesByContentId(contentId);
      final existingEpisode = episodes.isNotEmpty ? episodes.first : null;

      if (existingEpisode != null) {
        await _episodeRepo.updateEpisode(
          movieEpisode.copyWith(id: existingEpisode.id),
        );
      } else {
        await _episodeRepo.insertEpisode(movieEpisode);
      }

      // SCRIBE: Save metadata.json
      await _metadataService.scribeMetadata(
        content: updatedContent,
        episodes: [movieEpisode],
        directoryPath: podDir,
      );

      _updateState(progress: 1.0);
      return updatedContent;
    } finally {
      _updateState(isImporting: false);
    }
  }

  Future<void> updateMovieFile(
    Content content,
    String sourceFilePath, {
    void Function(double)? onProgress,
  }) async {
    if (_isImporting) throw StateError('An import is already in progress');
    if (content.id == null) return;

    final episodes = await _episodeRepo.getEpisodesByContentId(content.id!);
    if (episodes.isEmpty) return;

    final ep = episodes.first;
    final oldPath = ep.videoPath;

    final destPath = await _movieDestPath(content, sourceFilePath);
    final podDir = p.dirname(destPath);

    _updateState(isImporting: true, title: content.title, progress: 0);

    try {
      // 1. Move new file
      await _moveFile(
        sourceFilePath,
        destPath,
        onProgress: (p) => _updateState(progress: p * 0.9),
      );

      // 2. Update DB
      final updatedEp = ep.copyWith(videoPath: destPath, hasFile: true);
      await _episodeRepo.updateEpisode(updatedEp);
      await _contentRepo.updateContent(content.copyWith(hasFile: true));

      // 3. Update Metadata
      await _metadataService.scribeMetadata(
        content: content.copyWith(hasFile: true),
        episodes: [updatedEp],
        directoryPath: podDir,
      );

      _updateState(progress: 1.0);

      // 4. Delete old file if different
      if (oldPath != null && oldPath != destPath) {
        final file = File(oldPath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }
    } finally {
      _updateState(isImporting: false);
    }
  }

  Future<void> updateEpisodeFile(
    Content content,
    Episode episode,
    String sourceFilePath, {
    void Function(double)? onProgress,
  }) async {
    if (content.id == null || episode.id == null) return;

    final oldPath = episode.videoPath;
    final podDir = await _seriesPodDir(content);
    final destPath = await _seriesEpisodeDestPath(
      podDir,
      content,
      episode.seasonNumber!,
      episode.episodeNumber!,
      sourceFilePath,
    );

    // 1. Move new file
    await _moveFile(sourceFilePath, destPath, onProgress: onProgress);

    // 2. Update DB
    final updatedEp = episode.copyWith(videoPath: destPath, hasFile: true);
    await _episodeRepo.updateEpisode(updatedEp);

    // 3. Update Metadata
    final allEpisodes = await _episodeRepo.getEpisodesByContentId(content.id!);
    await _metadataService.scribeMetadata(
      content: content,
      episodes: allEpisodes,
      directoryPath: podDir,
    );

    // 4. Delete old file if different
    if (oldPath != null && oldPath != destPath) {
      final file = File(oldPath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
  }

  Future<Content> importSeries(
    Content content,
    Map<int, Map<int, String>> episodeFilePaths, {
    void Function(double)? onProgress,
  }) async {
    if (_isImporting) throw StateError('An import is already in progress');
    if (content.tmdbId == null) throw ArgumentError('tmdbId required');

    _updateState(isImporting: true, title: content.title, progress: 0);

    try {
      final existingContent = await _contentRepo.getContentByTmdbId(
        content.tmdbId!,
      );
      final contentId =
          existingContent?.id ?? await _contentRepo.insertContent(content);

      if (existingContent != null) {
        await _contentRepo.updateContent(content.copyWith(id: contentId));
      }

      final podDir = await _seriesPodDir(content);

      // Download artwork to pod
      final artwork = await _artworkService.downloadArtwork(
        content: content,
        posterTmdbPath: content.posterPath,
        backdropTmdbPath: content.backdropPath,
        targetDirectory: podDir,
      );

      final updatedContent = content.copyWith(
        id: contentId,
        localPosterPath: artwork.posterPath,
        localBackdropPath: artwork.backdropPath,
        status: StatusType.ready.name,
      );
      await _contentRepo.updateContent(updatedContent);

      // Progress tracking
      int totalFiles = 0;
      for (final season in episodeFilePaths.values) {
        totalFiles += season.length;
      }
      int filesDone = 0;

      final List<Episode> allEpisodesForMetadata = [];

      for (final seasonEntry in episodeFilePaths.entries) {
        final seasonNumber = seasonEntry.key;
        final episodeFiles = seasonEntry.value;

        List<EpisodeApi> tmdbEpisodes = [];
        try {
          final seasonData = await _tmdbService.getSeasonDetails(
            content.tmdbId!,
            seasonNumber,
          );
          final episodeList = seasonData['episodes'] as List? ?? [];
          tmdbEpisodes = episodeList
              .map((e) => EpisodeApi.fromMap(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}

        final tmdbMap = {for (final e in tmdbEpisodes) e.episodeNumber: e};

        for (final entry in episodeFiles.entries) {
          final episodeNumber = entry.key;
          final sourceFilePath = entry.value;

          final destPath = await _seriesEpisodeDestPath(
            podDir,
            content,
            seasonNumber,
            episodeNumber,
            sourceFilePath,
          );

          await _moveFile(
            sourceFilePath,
            destPath,
            onProgress: (p) {
              if (totalFiles > 0) {
                _updateState(progress: (filesDone + p) / totalFiles);
              }
            },
          );
          filesDone++;

          final tmdbEp = tmdbMap[episodeNumber];
          final existingEpisode = await _episodeRepo.getEpisode(
            contentId,
            seasonNumber,
            episodeNumber,
          );

          final Episode episode;
          if (tmdbEp != null) {
            episode = Episode.fromApi(tmdbEp, contentId).copyWith(
              id: existingEpisode?.id,
              videoPath: destPath,
              hasFile: true,
            );
          } else {
            episode =
                (existingEpisode ??
                        Episode(
                          contentId: contentId,
                          seasonNumber: seasonNumber,
                          episodeNumber: episodeNumber,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ))
                    .copyWith(videoPath: destPath, hasFile: true);
          }

          if (existingEpisode != null) {
            await _episodeRepo.updateEpisode(episode);
          } else {
            await _episodeRepo.insertEpisode(episode);
          }
          allEpisodesForMetadata.add(episode);
        }
      }

      // SCRIBE: Save metadata.json
      await _metadataService.scribeMetadata(
        content: updatedContent,
        episodes: allEpisodesForMetadata,
        directoryPath: podDir,
      );

      _updateState(progress: 1.0);
      return updatedContent;
    } finally {
      _updateState(isImporting: false);
    }
  }

  Future<String> _movieDestPath(Content content, String sourceFilePath) async {
    final krateDir = await _storageService.getKrateDir();
    final safeTitle = TitleCleaner.clean(content.title);
    final year = content.releaseDate?.year;
    final tmdbId = content.tmdbId;

    // Naming convention: Title_Year_TMDBID
    final folderName = '${safeTitle}_${year ?? '0000'}_$tmdbId';
    final fileName = safeTitle;
    final ext = _extension(sourceFilePath);
    final dir = Directory('$krateDir/movies/$folderName');
    await dir.create(recursive: true);
    return '${dir.path}/$fileName$ext';
  }

  Future<String> _seriesPodDir(Content content) async {
    final krateDir = await _storageService.getKrateDir();
    final safeTitle = TitleCleaner.clean(content.title);
    final year = content.releaseDate?.year;
    final tmdbId = content.tmdbId;
    final folderName = '${safeTitle}_${year ?? '0000'}_$tmdbId';
    final dir = Directory('$krateDir/series/$folderName');
    await dir.create(recursive: true);
    return dir.path;
  }

  Future<String> _seriesEpisodeDestPath(
    String podDir,
    Content content,
    int season,
    int episode,
    String sourceFilePath,
  ) async {
    final safeTitle = TitleCleaner.clean(content.title);
    final seasonStr = 'S${season.toString().padLeft(2, '0')}';
    final episodeStr = 'E${episode.toString().padLeft(2, '0')}';
    final ext = _extension(sourceFilePath);

    final dir = Directory(
      '$podDir/Season_${season.toString().padLeft(2, '0')}/Episode_${episode.toString().padLeft(2, '0')}',
    );
    await dir.create(recursive: true);
    return '${dir.path}/${safeTitle}_$seasonStr$episodeStr$ext';
  }

  String _extension(String path) {
    final dot = path.lastIndexOf('.');
    return dot != -1 ? path.substring(dot) : '.mp4';
  }

  Future<void> _moveFile(
    String src,
    String dest, {
    void Function(double)? onProgress,
  }) async {
    final source = File(src);
    final destination = File(dest);

    try {
      if (await destination.exists()) {
        await destination.delete();
      }
      await source.rename(dest);
      onProgress?.call(1.0);
      return;
    } catch (_) {}

    await _copyWithProgress(source, destination, onProgress);
    await source.delete();
  }

  Future<void> _copyWithProgress(
    File source,
    File destination,
    void Function(double)? onProgress,
  ) async {
    final totalBytes = await source.length();
    int copiedBytes = 0;

    final reader = source.openRead();
    final writer = destination.openWrite();

    try {
      await for (final chunk in reader) {
        writer.add(chunk);
        copiedBytes += chunk.length;
        if (totalBytes > 0) {
          onProgress?.call(copiedBytes / totalBytes);
        }
      }
    } finally {
      await writer.close();
    }
  }

  Future<void> deleteContent(
    Content content, {
    bool deleteFiles = false,
  }) async {
    if (content.id == null) return;

    final episodes = await _episodeRepo.getEpisodesByContentId(content.id!);

    if (deleteFiles) {
      // 1. Delete DB records
      await _contentRepo.deleteContent(content.id!);

      for (final ep in episodes) {
        if (ep.videoPath != null) {
          final file = File(ep.videoPath!);
          if (await file.exists()) {
            try {
              // Deleting the pod folder entirely
              final podDir = p.dirname(
                content.contentType == ContentType.movie
                    ? ep.videoPath!
                    : p.dirname(p.dirname(p.dirname(ep.videoPath!))),
              );

              final dir = Directory(podDir);
              if (await dir.exists()) {
                await dir.delete(recursive: true);
              }
              break; // Done after deleting pod root
            } catch (_) {}
          }
        }
      }
    } else {
      // Library-Only removal
      // We don't delete files, but we mark hasFile = false in DB and scribed JSON
      await _contentRepo.updateContent(content.copyWith(hasFile: false));
      for (final ep in episodes) {
        await _episodeRepo.updateEpisode(ep.copyWith(hasFile: false));
      }

      // Update JSON if possible
      for (final ep in episodes) {
        if (ep.videoPath != null) {
          final podDir = p.dirname(
            content.contentType == ContentType.movie
                ? ep.videoPath!
                : p.dirname(p.dirname(p.dirname(ep.videoPath!))),
          );

          await _metadataService.scribeMetadata(
            content: content.copyWith(hasFile: false),
            episodes: episodes.map((e) => e.copyWith(hasFile: false)).toList(),
            directoryPath: podDir,
          );
          break;
        }
      }
    }
  }

  Future<void> deleteEpisodes(
    Content content,
    List<Episode> episodes, {
    bool deleteFiles = false,
  }) async {
    for (final ep in episodes) {
      if (ep.id == null) continue;

      if (deleteFiles && ep.videoPath != null) {
        final file = File(ep.videoPath!);
        if (await file.exists()) {
          try {
            await file.delete();
            // Cleanup empty subfolders
            final epDir = file.parent;
            if (await epDir.exists() && (await epDir.list().isEmpty))
              await epDir.delete();
            final seasonDir = epDir.parent;
            if (await seasonDir.exists() && (await seasonDir.list().isEmpty))
              await seasonDir.delete();
          } catch (_) {}
        }
      }

      await _episodeRepo.updateEpisode(
        ep.copyWith(videoPath: null, hasFile: false),
      );
    }

    // Re-scribe metadata
    final allEpisodes = await _episodeRepo.getEpisodesByContentId(content.id!);
    if (allEpisodes.isNotEmpty && allEpisodes.first.videoPath != null) {
      final podDir = p.dirname(
        content.contentType == ContentType.movie
            ? allEpisodes.first.videoPath!
            : p.dirname(p.dirname(p.dirname(allEpisodes.first.videoPath!))),
      );
      await _metadataService.scribeMetadata(
        content: content,
        episodes: allEpisodes,
        directoryPath: podDir,
      );
    }
  }
}
