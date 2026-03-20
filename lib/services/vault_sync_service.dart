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

// One-pass scanner to reconcile the filesystem with the database and metadata.json.
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
    debugPrint('[VaultSync] Starting sync...');
    onStatus?.call('Gathering vault files...');
    final root = await storageService.getRoot();
    if (root == null) {
      debugPrint('[VaultSync] Aborting: No storage root configured.');
      return;
    }

    final vaultDir = Directory('$root/$kVaultFolderName');
    if (!await vaultDir.exists()) {
      debugPrint('[VaultSync] Aborting: Vault directory not found at ${vaultDir.path}');
      return;
    }

    final foundTmdbIds = <int>{};
    final pods = <Directory>[];

    // Collect all pods
    for (final typeDir in [kMoviesDirName, kSeriesDirName]) {
      final dir = Directory('${vaultDir.path}/$typeDir');
      if (await dir.exists()) {
        await for (var entity in dir.list()) {
          if (entity is Directory) {
            pods.add(entity);
            final id = _extractTmdbId(entity.path);
            if (id != null) foundTmdbIds.add(id);
          }
        }
      }
    }

    debugPrint('[VaultSync] Found ${pods.length} pods on disk.');

    if (pods.isEmpty) {
      debugPrint('[VaultSync] Vault is empty.');
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
        debugPrint('[VaultSync] Skipping: Invalid folder name format: ${pod.path}');
        continue;
      }
      
      final isSeries = pod.path.contains(kSeriesDirName);
      debugPrint('[VaultSync] Syncing Pod [$tmdbId] (${isSeries ? "Series" : "Movie"}): ${_baseName(pod.path)}');
      
      onStatus?.call('Syncing ${_baseName(pod.path)}...');
      await _syncPod(pod, tmdbId, isSeries);
    }

    // Detect Ghosts (DB entries not on disk)
    debugPrint('[VaultSync] Checking for ghost entries in DB...');
    onStatus?.call('Marking missing entries...');
    final allContent = await contentRepo.getAll();
    int markedMissing = 0;
    
    for (final content in allContent) {
      if (content.tmdbId != null && !foundTmdbIds.contains(content.tmdbId)) {
        if (content.fileStatus != FileStatus.ready) continue; 
        
        debugPrint('[VaultSync] Ghost detected: Pod folder missing for ${content.title} (ID: ${content.tmdbId}).');
        await _markContentAsMissing(content);
        markedMissing++;
      } else if (content.fileStatus == FileStatus.ready) {
        // Pod exists, but maybe file was manually deleted?
        // _syncPod already handles this and updates DB, 
        // but we want to know if sync discovered missing files.
      }
    }

    debugPrint('[VaultSync] Sync complete. Folders missing: $markedMissing. Entries reconcilled.');
    onStatus?.call('Vault sync complete');
    onProgress?.call(1.0);
  }

  // Sync a specific pod directory.
  Future<void> syncPod(Directory pod) async {
    final tmdbId = _extractTmdbId(pod.path);
    if (tmdbId == null) return;
    await _syncPod(pod, tmdbId, pod.path.contains(kSeriesDirName));
  }

  // Quickly check if there are differences between the vault and the database.
  // Returns `true` if a sync is recommended.
  Future<bool> scout() async {
    debugPrint('[VaultSync] Scouting vault...');
    final root = await storageService.getRoot();
    if (root == null) return false;

    final vaultDir = Directory('$root/$kVaultFolderName');
    if (!await vaultDir.exists()) return false;

    final diskIds = <int>{};
    for (final typeDir in [kMoviesDirName, kSeriesDirName]) {
      final dir = Directory('${vaultDir.path}/$typeDir');
      if (await dir.exists()) {
        await for (var entity in dir.list()) {
          if (entity is Directory) {
            final id = _extractTmdbId(entity.path);
            if (id != null) diskIds.add(id);
          }
        }
      }
    }

    final allContent = await contentRepo.getAll();
    // We compare with ALL content in the DB. 
    // If it's on disk but the DB doesn't know it (or thinks it's missing), we need sync.
    // If it's in DB (not missing) but NOT on disk, we need sync.
    final dbReadyIds = allContent
        .where((c) => c.fileStatus != FileStatus.missing)
        .map((c) => c.tmdbId)
        .whereType<int>()
        .toSet();

    // 1. New things on disk?
    for (final id in diskIds) {
      if (!dbReadyIds.contains(id)) {
        debugPrint('[VaultSync] Scout: Found new/missing-in-db content on disk (ID: $id). Sync recommended.');
        return true;
      }
    }

    // 2. Gone from disk? (Folder missing)
    for (final id in dbReadyIds) {
      if (!diskIds.contains(id)) {
        debugPrint('[VaultSync] Scout: Pod folder for ID: $id is no longer on disk. Sync recommended.');
        return true;
      }
    }

    // 3. Deep check (Media missing for movies)
    // For series it's more expensive to scout deeply every startup, 
    // so we prioritize movies as they are the most common "single file" case.
    for (final content in allContent) {
      if (content.contentType == ContentType.movie && 
          content.fileStatus == FileStatus.ready && 
          content.podPath != null) {
        final podDir = Directory(content.podPath!);
        if (await podDir.exists()) {
          final hasVideo = await _findAnyVideoFile(podDir) != null;
          if (!hasVideo) {
            debugPrint('[VaultSync] Scout: Media file missing for movie "${content.title}" (ID: ${content.tmdbId}). Sync recommended.');
            return true;
          }
        }
      }
    }

    debugPrint('[VaultSync] Scout: Vault is in sync with DB.');
    return false;
  }

  Future<void> _syncPod(Directory pod, int tmdbId, bool isSeries) async {
    Content? content;
    List<Episode> episodes = [];

    // Try reading metadata.json
    final metadataFile = File('${pod.path}/$kMetadataFileName');
    if (await metadataFile.exists()) {
      try {
        debugPrint('[VaultSync] Pod [$tmdbId]: Reading metadata.json');
        final data = await metadataService.read(metadataFile.path);
        content = data.content;
        episodes = data.episodes;
      } catch (e) {
        debugPrint('[VaultSync] Pod [$tmdbId]: Error reading metadata: $e');
      }
    }

    // Process metadata if found, or recover if missing
    if (content != null) {
      // metadata.json was successfully parsed!
      // Check if we already have it in DB by TMDB ID
      final existingDbContent = await contentRepo.getByTmdbId(tmdbId);

      if (existingDbContent != null) {
        // Exists in DB, we just grab its ID and ensure podPath is fresh
        content = existingDbContent.copyWith(podPath: pod.path);
      } else {
        // COMPLETELY NEW TO DB AND WE ARE OFFLINE!
        // We trust the metadata.json completely and insert it directly.
        content = content.copyWith(podPath: pod.path);
        final id = await contentRepo.upsert(content);
        content = content.copyWith(id: id);
      }
    } else {
      // metadata.json missing or corrupt. We must recover from DB or TMDB.
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
        // Found in DB, ensure podPath is correct
        if (content.podPath == null || content.podPath != pod.path) {
          content = content.copyWith(podPath: pod.path);
        }
      }
    }

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
      // Try to get existing episode from DB first to get its ID
      final existingEpisode = await episodeRepo.getMovieEpisode(contentId);

      final movieEpisode = episodes.isNotEmpty
          ? episodes.first.copyWith(id: existingEpisode?.id)
          : (existingEpisode ??
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
        debugPrint('[VaultSync] Pod [$tmdbId]: NO MEDIA FILE FOUND for movie.');
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
        final episodeDir = Directory(
          '${pod.path}/Season_$seasonStr/$kEpisodeDirPrefix$episodeStr',
        );

        File? matchedFile;
        if (await episodeDir.exists()) {
          // Any video file here explicitly belongs to this episode
          matchedFile = await _findAnyVideoFile(episodeDir);
        }

        if (matchedFile != null) {
          anyReady = true;
          syncedEpisodes.add(
            ep.copyWith(
              videoPath: matchedFile.path,
              fileStatus: FileStatus.ready,
            ),
          );
        } else {
          debugPrint('[VaultSync] Pod [$tmdbId]: NO MEDIA FILE FOUND for S$seasonStr E$episodeStr');
          syncedEpisodes.add(
            ep.copyWith(clearVideoPath: true, fileStatus: FileStatus.missing),
          );
        }
      }
      content = content.copyWith(
        fileStatus: anyReady ? FileStatus.ready : FileStatus.missing,
      );
    }

    final existing = await contentRepo.getById(contentId);
    final updatedContent = content.copyWith(
      isFavorite: existing?.isFavorite ?? false,
      createdAt: existing?.createdAt,
      updatedAt: DateTime.now(),
    );
    
    debugPrint('[VaultSync] Pod [$tmdbId]: Updating Content DB entry (${updatedContent.title})');
    await contentRepo.update(updatedContent);

    for (final ep in syncedEpisodes) {
      await episodeRepo.upsert(ep);
    }

    await metadataService.scribe(
      content: updatedContent,
      episodes: syncedEpisodes,
      podPath: pod.path,
    );

    // If artwork was missing but we have internet, maybe download? Manual muna
    // For now, just ensure metadata.json is consistent with local disk.
  }

  Future<void> _markContentAsMissing(Content content) async {
    debugPrint('[VaultSync] Marking content as missing: ${content.title}');
    await contentRepo.update(
      content.copyWith(
        fileStatus: FileStatus.missing,
        clearLocalPosterPath: true,
        clearLocalBackdropPath: true,
      ),
    );
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
