import 'dart:io' hide ContentType;
import 'package:flutter/foundation.dart';
import 'package:krate/models/app/content.dart';
import 'package:krate/models/app/episode.dart';
import 'package:krate/repositories/content_repository.dart';
import 'package:krate/repositories/episode_repository.dart';
import 'package:krate/services/metadata_service.dart';
import 'package:krate/services/storage_service.dart';
import 'package:krate/constants.dart';
import 'package:path/path.dart' as p;

/// The "Heartbeat" of Krate. Scans the storage root, reconciles .metadata.json
/// files with the filesystem, and updates the database cache.
class ScannerService extends ChangeNotifier {
  ContentRepository _contentRepo;
  EpisodeRepository _episodeRepo;
  MetadataService _metadataService;
  StorageService _storageService;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  double _progress = 0;
  double get progress => _progress;

  String _status = '';
  String get status => _status;

  ScannerService({
    required ContentRepository contentRepo,
    required EpisodeRepository episodeRepo,
    required MetadataService metadataService,
    required StorageService storageService,
  }) : _contentRepo = contentRepo,
       _episodeRepo = episodeRepo,
       _metadataService = metadataService,
       _storageService = storageService;

  void updateDependencies({
    required ContentRepository contentRepo,
    required EpisodeRepository episodeRepo,
    required MetadataService metadataService,
    required StorageService storageService,
  }) {
    _contentRepo = contentRepo;
    _episodeRepo = episodeRepo;
    _metadataService = metadataService;
    _storageService = storageService;
  }

  /// Performs a full scan and reconciliation of the library storage root.
  Future<void> scanLibrary() async {
    if (_isScanning) return;
    _isScanning = true;
    _progress = 0;
    _status = 'Scanning for media pods...';
    notifyListeners();

    try {
      final krateDir = await _storageService.getKrateDir();
      final List<Directory> podDirs = [];

      // 1. Discover pods (folders containing .metadata.json)
      final moviesDir = Directory(p.join(krateDir, 'movies'));
      final seriesDir = Directory(p.join(krateDir, 'series'));

      if (await moviesDir.exists()) {
        await for (final entity in moviesDir.list()) {
          if (entity is Directory) podDirs.add(entity);
        }
      }
      if (await seriesDir.exists()) {
        await for (final entity in seriesDir.list()) {
          if (entity is Directory) podDirs.add(entity);
        }
      }

      if (podDirs.isEmpty) {
        _isScanning = false;
        notifyListeners();
        return;
      }

      // 2. Reconcile each pod found on disk
      for (int i = 0; i < podDirs.length; i++) {
        final dir = podDirs[i];
        final metadataFile = File(
          p.join(dir.path, MetadataService.metadataFileName),
        );

        _status = 'Analyzing ${p.basename(dir.path)}...';
        _progress = (i / podDirs.length) * 0.7; // Disk-to-DB is first 70%
        notifyListeners();

        if (await metadataFile.exists()) {
          await _reconcilePod(dir.path, metadataFile.path);
        }
      }

      // 3. DB-to-FS Reconciliation (Handle Ghost Pods / Deleted Folders)
      _status = 'Cleaning up ghost records...';
      _progress = 0.8;
      notifyListeners();

      final allContent = await _contentRepo.getAllContent();
      for (final content in allContent) {
        // Find the metadata file in the pod directory
        final krateDir = await _storageService.getKrateDir();
        final typeSubDir = content.contentType == ContentType.movie
            ? 'movies'
            : 'series';

        // We need to find the folder. In Phase 14 we adopted Title_Year_TMDBID.
        // If we can't find it by that, we should check if any folder in that subdir
        // has a .metadata.json that matches this TMDB ID.

        // For now, let's assume the standard path or search for the pod
        bool podExists = false;
        final parentDir = Directory(p.join(krateDir, typeSubDir));
        if (await parentDir.exists()) {
          await for (final entity in parentDir.list()) {
            if (entity is Directory) {
              final metaFile = File(
                p.join(entity.path, MetadataService.metadataFileName),
              );
              if (await metaFile.exists()) {
                final metadata = await _metadataService.readMetadata(
                  metaFile.path,
                );
                final Content metaContent = metadata['content'];
                if (metaContent.tmdbId == content.tmdbId) {
                  podExists = true;
                  // Now deeper check for actual media files inside this pod
                  await _reconcilePod(entity.path, metaFile.path);
                  break;
                }
              }
            }
          }
        }

        if (!podExists) {
          // The entire pod directory is missing!
          if (content.hasFile) {
            await _contentRepo.updateContent(content.copyWith(hasFile: false));
            // Also mark all episodes as missing
            final episodes = await _episodeRepo.getEpisodesByContentId(
              content.id!,
            );
            for (final ep in episodes) {
              if (ep.hasFile) {
                await _episodeRepo.updateEpisode(ep.copyWith(hasFile: false));
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Scan failed: $e');
    } finally {
      _isScanning = false;
      _progress = 1.0;
      _status = 'Scan complete';
      notifyListeners();
    }
  }

  /// Reconciles a single pod directory with the database.
  Future<void> _reconcilePod(String podPath, String metadataPath) async {
    try {
      final metadata = await _metadataService.readMetadata(metadataPath);
      Content content = metadata['content'];
      List<Episode> episodes = metadata['episodes'];

      // 3. Physical Reconciliation: Check if files actually exist
      bool contentHasFile = false;
      final List<Episode> reconciledEpisodes = [];

      for (final ep in episodes) {
        bool epHasFile = false;
        if (ep.videoPath != null) {
          if (await File(ep.videoPath!).exists()) {
            epHasFile = true;
          }
        }

        final reconciledEp = ep.copyWith(hasFile: epHasFile);
        reconciledEpisodes.add(reconciledEp);
        if (epHasFile) contentHasFile = true;
      }

      // Update content object with actual existence status
      content = content.copyWith(hasFile: contentHasFile);

      // 4. Sync with Database Cache
      final existingContent = await _contentRepo.getContentByTmdbId(
        content.tmdbId!,
      );
      final int contentId;

      if (existingContent != null) {
        contentId = existingContent.id!;
        await _contentRepo.updateContent(
          content.copyWith(
            id: contentId,
            isFavorite: existingContent.isFavorite, // Preserve user preference
          ),
        );
      } else {
        contentId = await _contentRepo.insertContent(content);
      }

      // Update episodes
      for (final ep in reconciledEpisodes) {
        final Episode? existingEp;
        if (content.contentType == ContentType.movie) {
          final all = await _episodeRepo.getEpisodesByContentId(contentId);
          existingEp = all.isNotEmpty ? all.first : null;
        } else {
          existingEp = await _episodeRepo.getEpisode(
            contentId,
            ep.seasonNumber!,
            ep.episodeNumber!,
          );
        }

        if (existingEp != null) {
          await _episodeRepo.updateEpisode(
            ep.copyWith(id: existingEp.id, contentId: contentId),
          );
        } else {
          await _episodeRepo.insertEpisode(ep.copyWith(contentId: contentId));
        }
      }
    } catch (e) {
      debugPrint('Failed to reconcile pod $podPath: $e');
    }
  }
}
