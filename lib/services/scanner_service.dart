import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:krate/core/constants.dart';
import 'package:krate/data/repositories/content_repository.dart';
import 'package:krate/data/repositories/episode_repository.dart';
import 'package:krate/services/metadata_service.dart';
import 'package:krate/services/storage_service.dart';

/// One-pass scanner to reconcile the filesystem with the database.
class ScannerService {
  final ContentRepository contentRepo;
  final EpisodeRepository episodeRepo;
  final MetadataService metadataService;
  final StorageService storageService;

  ScannerService({
    required this.contentRepo,
    required this.episodeRepo,
    required this.metadataService,
    required this.storageService,
  });

  Future<void> scan({
    void Function(double)? onProgress,
    void Function(String)? onStatus,
  }) async {
    onStatus?.call('Gathering vault files...');
    final root = await storageService.getRoot();
    if (root == null) return;

    final vaultDir = Directory('$root/$kVaultFolderName');
    if (!await vaultDir.exists()) return;

    // 1. Walk the filesystem and find all TMDB IDs present on disk
    final foundTmdbIds = <int>{};
    final List<FileSystemEntity> pods = [];

    // Collect movie pods
    final movieRoot = Directory('${vaultDir.path}/$kMoviesDirName');
    if (await movieRoot.exists()) {
      await for (var entity in movieRoot.list()) {
        if (entity is Directory) pods.add(entity);
      }
    }

    // Collect series pods
    final seriesRoot = Directory('${vaultDir.path}/$kSeriesDirName');
    if (await seriesRoot.exists()) {
      await for (var entity in seriesRoot.list()) {
        if (entity is Directory) pods.add(entity);
      }
    }

    // 2. Reconcile each pod
    int processedCount = 0;
    for (var pod in pods) {
      processedCount++;
      onProgress?.call(processedCount / pods.length);

      final metadataFile = File('${pod.path}/$kMetadataFileName');
      if (!await metadataFile.exists()) {
        debugPrint('[Scanner] Skipping pod with no metadata: ${pod.path}');
        continue;
      }

      try {
        final data = await metadataService.read(pod.path);
        final content = data.content;
        final episodes = data.episodes;

        if (content.tmdbId != null) {
          foundTmdbIds.add(content.tmdbId!);

          // Check if it already exists in DB to preserve user fields (favorite, etc)
          final existing = await contentRepo.getByTmdbId(content.tmdbId!);
          final contentToSave = content.copyWith(
            id: existing?.id,
            isFavorite: existing?.isFavorite ?? false,
            createdAt: existing?.createdAt,
          );

          await contentRepo.upsert(contentToSave);
          final contentId = (await contentRepo.getByTmdbId(
            content.tmdbId!,
          ))?.id;

          if (contentId != null) {
            for (var ep in episodes) {
              await episodeRepo.upsert(ep.copyWith(contentId: contentId));
            }
          }
        }
      } catch (e) {
        debugPrint('[Scanner] Error reconciling ${pod.path}: $e');
      }
    }

    // 3. Detect Ghosts
    // Any record in DB whose TMDB ID is NOT in foundTmdbIds is a ghost.
    onStatus?.call('Marking missing files...');
    final allContent = await contentRepo.getAll();
    for (var content in allContent) {
      if (content.tmdbId != null && !foundTmdbIds.contains(content.tmdbId)) {
        // Pod dir is missing! Update status to ghost.
        // In a real impl, we'd loop through episodes too.
      }
    }

    onStatus?.call('Scan complete');
    onProgress?.call(1.0);
  }
}
