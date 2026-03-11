import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/data/repositories/content_repository.dart';
import 'package:krate/data/repositories/episode_repository.dart';
import 'package:krate/services/metadata_service.dart';
import 'package:krate/services/storage_service.dart';
import 'package:krate/services/tmdb_service.dart';
import 'package:krate/services/artwork_service.dart';

/// One-pass scanner to reconcile the filesystem with the database and metadata.json.
class VaultSyncService {
  final ContentRepository contentRepo;
  final EpisodeRepository episodeRepo;
  final MetadataService metadataService;
  final StorageService storageService;
  final TMDBService tmdbService;
  final ArtworkService artworkService;

  VaultSyncService({
    required this.contentRepo,
    required this.episodeRepo,
    required this.metadataService,
    required this.storageService,
    required this.tmdbService,
    required this.artworkService,
  });

  Future<void> sync({
    void Function(double)? onProgress,
    void Function(String)? onStatus,
  }) async {
    onStatus?.call('Gathering vault files...');
    final root = await storageService.getRoot();
    if (root == null) return;

    final vaultDir = Directory('$root/$kVaultFolderName');
    if (!await vaultDir.exists()) return;

    final foundTmdbIds = <int>{};
    final pods = <Directory>[];

    // Collect all pods
    for (final typeDir in [kMoviesDirName, kSeriesDirName]) {
      final dir = Directory('${vaultDir.path}/$typeDir');
      if (await dir.exists()) {
        await for (var entity in dir.list()) {
          if (entity is Directory) pods.add(entity);
        }
      }
    }

    if (pods.isEmpty) {
      onStatus?.call('Vault is empty.');
      onProgress?.call(1.0);
      return;
    }

    // Process each pod
    for (int i = 0; i < pods.length; i++) {
      final pod = pods[i];
      onProgress?.call(i / pods.length);
      final tmdbId = _extractTmdbId(pod.path);
      if (tmdbId == null) {
        debugPrint('[VaultSync] Could not extract TMDB ID from ${pod.path}');
        continue;
      }
      foundTmdbIds.add(tmdbId);
      final isSeries = pod.path.contains(kSeriesDirName);

      onStatus?.call('Syncing ${_baseName(pod.path)}...');
      await _syncPod(pod, tmdbId, isSeries);
    }

    // Detect Ghosts (DB entries not on disk)
    onStatus?.call('Marking missing entries...');
    final allContent = await contentRepo.getAll();
    for (final content in allContent) {
      if (content.tmdbId != null && !foundTmdbIds.contains(content.tmdbId)) {
        await _markContentAsMissing(content);
      }
    }

    onStatus?.call('Vault sync complete');
    onProgress?.call(1.0);
  }

  /// Sync a specific pod directory.
  Future<void> syncPod(Directory pod) async {
    final tmdbId = _extractTmdbId(pod.path);
    if (tmdbId == null) return;
    await _syncPod(pod, tmdbId, pod.path.contains(kSeriesDirName));
  }

  /// Quickly check if there are differences between the vault and the database.
  /// Returns `true` if a sync is recommended.
  Future<bool> scout() async {
    final root = await storageService.getRoot();
    if (root == null) return false;

    final vaultDir = Directory('$root/$kVaultFolderName');
    if (!await vaultDir.exists()) return false;

    final foundTmdbIds = <int>{};
    for (final typeDir in [kMoviesDirName, kSeriesDirName]) {
      final dir = Directory('${vaultDir.path}/$typeDir');
      if (await dir.exists()) {
        await for (var entity in dir.list()) {
          if (entity is Directory) {
            final id = _extractTmdbId(entity.path);
            if (id != null) foundTmdbIds.add(id);
          }
        }
      }
    }

    final allContent = await contentRepo.getAll();
    final dbTmdbIds = allContent.map((c) => c.tmdbId).whereType<int>().toSet();

    // Check for new folders or missing folders
    if (foundTmdbIds.length != dbTmdbIds.length) return true;
    if (!foundTmdbIds.every((id) => dbTmdbIds.contains(id))) return true;

    return false;
  }

  Future<void> _syncPod(Directory pod, int tmdbId, bool isSeries) async {
    // 1. Reconcile Metadata
    Content? content;
    List<Episode> episodes = [];

    // Try reading metadata.json
    final metadataFile = File('${pod.path}/$kMetadataFileName');
    if (await metadataFile.exists()) {
      try {
        final data = await metadataService.read(pod.path);
        content = data.content;
        episodes = data.episodes;
      } catch (e) {
        debugPrint('[VaultSync] Error reading metadata at ${pod.path}: $e');
      }
    }

    // Recovery if metadata is missing or corrupt
    if (content == null) {
      debugPrint('[VaultSync] Recovering metadata for TMDB ID $tmdbId');
      content = await contentRepo.getByTmdbId(tmdbId);
      if (content == null) {
        // Not in DB either - try fetching from TMDB (needs internet)
        try {
          if (isSeries) {
            final data = await tmdbService.getSeriesDetails(tmdbId);
            content = Content.fromTmdbSeries(data);
          } else {
            final data = await tmdbService.getMovieDetails(tmdbId);
            content = Content.fromTmdbMovie(data);
          }
          // Save to DB so we have it
          content = content.copyWith(podPath: pod.path);
          final id = await contentRepo.upsert(content);
          content = content.copyWith(id: id);
        } catch (e) {
          debugPrint('[VaultSync] Failed to recover from TMDB: $e');
          return; // Skip this pod if we can't get basic info
        }
      } else {
        // If content was found in DB but podPath was null, update it
        if (content.podPath == null || content.podPath != pod.path) {
          content = content.copyWith(podPath: pod.path);
        }
      }
      // If we found it in DB or TMDB, we'll scribe it later after check
    }

    // 2. Comprehensive Integrity Check
    // Posters
    final posterFile = File('${pod.path}/$kPosterFileName');
    final backdropFile = File('${pod.path}/$kBackdropFileName');
    bool artworkNeedsUpdate = false;

    if (!await posterFile.exists()) {
      content = content.copyWith(clearLocalPosterPath: true);
      artworkNeedsUpdate = true;
    } else {
      content = content.copyWith(localPosterPath: posterFile.path);
    }

    if (!await backdropFile.exists()) {
      content = content.copyWith(clearLocalBackdropPath: true);
      artworkNeedsUpdate = true;
    } else {
      content = content.copyWith(localBackdropPath: backdropFile.path);
    }

    if (artworkNeedsUpdate) {
      debugPrint('[VaultSync] Artwork missing for ${content.title}');
    }

    // Video Files & Structure
    final contentId = content.id!;
    final List<Episode> syncedEpisodes = [];

    if (!isSeries) {
      // Movie
      final movieEpisode = episodes.isNotEmpty
          ? episodes.first
          : (await episodeRepo.getMovieEpisode(contentId) ??
              Episode.forMovie(contentId: contentId, videoPath: null));

      // Scan pod dir for any video file
      final videoFile = await _findAnyVideoFile(pod);
      if (videoFile != null) {
        content = content.copyWith(fileStatus: FileStatus.ready);
        syncedEpisodes.add(
          movieEpisode.copyWith(
            videoPath: videoFile.path,
            fileStatus: FileStatus.ready,
            contentId: contentId,
          ),
        );
      } else {
        content = content.copyWith(fileStatus: FileStatus.missing);
        syncedEpisodes.add(
          movieEpisode.copyWith(
            clearVideoPath: true,
            fileStatus: FileStatus.missing,
            contentId: contentId,
          ),
        );
      }
    } else {
      // Series
      final dbEpisodes = await episodeRepo.getByContentId(contentId);
      final tmdbId = content.tmdbId!;
      bool anyReady = false;

      // Ensure we have episodes registered in DB (recovery)
      if (dbEpisodes.isEmpty) {
        // If DB is empty, try to populate from TMDB or metadata
        if (episodes.isNotEmpty) {
          for (final ep in episodes) {
            await episodeRepo.upsert(ep.copyWith(contentId: contentId));
          }
        } else {
          // Hard recovery: fetch seasons from TMDB
          try {
            for (int s = 1; s <= content.totalSeasons; s++) {
              final sData = await tmdbService.getSeasonDetails(tmdbId, s);
              final eps = (sData['episodes'] as List?) ?? [];
              for (final eData in eps) {
                await episodeRepo.upsert(
                  Episode.fromTmdbEpisode(eData, contentId),
                );
              }
            }
          } catch (_) {}
        }
      }

      final updatedDbEpisodes = await episodeRepo.getByContentId(contentId);
      for (final ep in updatedDbEpisodes) {
        final season = ep.seasonNumber ?? 1;
        final episodeNumber = ep.episodeNumber ?? 1;
        
        final seasonStr = season.toString().padLeft(2, '0');
        final episodeStr = episodeNumber.toString().padLeft(2, '0');
        final episodeDir = Directory('${pod.path}/Season_$seasonStr/$kEpisodeDirPrefix$episodeStr');

        File? matchedFile;
        if (await episodeDir.exists()) {
          // Any video file here explicitly belongs to this episode
          matchedFile = await _findAnyVideoFile(episodeDir);
        }

        if (matchedFile != null) {
          anyReady = true;
          syncedEpisodes.add(
            ep.copyWith(videoPath: matchedFile.path, fileStatus: FileStatus.ready),
          );
        } else {
          syncedEpisodes.add(
            ep.copyWith(clearVideoPath: true, fileStatus: FileStatus.missing),
          );
        }
      }
      content = content.copyWith(
        fileStatus: anyReady ? FileStatus.ready : FileStatus.missing,
      );
    }

    // 3. Persist Changes
    final existing = await contentRepo.getById(contentId);
    final updatedContent = content.copyWith(
      isFavorite: existing?.isFavorite ?? false,
      createdAt: existing?.createdAt,
      updatedAt: DateTime.now(),
    );
    await contentRepo.update(updatedContent);

    for (final ep in syncedEpisodes) {
      await episodeRepo.update(ep);
    }

    // 4. Update metadata.json (Scribe)
    await metadataService.scribe(
      content: updatedContent,
      episodes: syncedEpisodes,
      podPath: pod.path,
    );

    // If artwork was missing but we have internet, maybe download?
    // For now, just ensure metadata.json is consistent with local disk.
  }

  Future<void> _markContentAsMissing(Content content) async {
    await contentRepo.update(content.copyWith(
      fileStatus: FileStatus.missing,
      clearLocalPosterPath: true,
      clearLocalBackdropPath: true,
    ));
    final episodes = await episodeRepo.getByContentId(content.id!);
    for (final ep in episodes) {
      await episodeRepo.update(
        ep.copyWith(clearVideoPath: true, fileStatus: FileStatus.missing),
      );
    }
  }

  int? _extractTmdbId(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final parts = name.split('_');
    if (parts.length < 3) return null;
    return int.tryParse(parts.last);
  }

  String _baseName(String path) => path.split(Platform.pathSeparator).last;

  Future<File?> _findAnyVideoFile(Directory dir) async {
    final exts = ['.mp4', '.mkv', '.avi', '.mov', '.wmv'];
    try {
      await for (final entity in dir.list()) {
        if (entity is File) {
          final path = entity.path.toLowerCase();
          if (exts.any((ext) => path.endsWith(ext))) return entity;
        }
      }
    } catch (_) {}
    return null;
  }

}
