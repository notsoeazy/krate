import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/data/models/watch_progress.dart';
import 'package:krate/data/repositories/episode_repository.dart';
import 'package:krate/data/repositories/watch_progress_repository.dart';
import 'package:krate/providers/providers.dart';

class WatchProgressService {
  final WatchProgressRepository _progressRepo;
  final EpisodeRepository _episodeRepo;
  final Ref _ref;

  WatchProgressService({
    required WatchProgressRepository progressRepo,
    required EpisodeRepository episodeRepo,
    required Ref ref,
  }) : _progressRepo = progressRepo,
       _episodeRepo = episodeRepo,
       _ref = ref;

  /// Determines the best episode to resume for a given content item.
  Future<Episode?> getResumeEpisode(int contentId) async {
    final allEpisodes = await _episodeRepo.getByContentId(contentId);
    if (allEpisodes.isEmpty) return null;

    final readyEpisodes = allEpisodes
        .where((ep) => ep.fileStatus == FileStatus.ready)
        .toList();
    if (readyEpisodes.isEmpty) {
      return allEpisodes.first; // No files, fallback to first metadata
    }

    // 1. Check for most recently watched unfinished episode that is ready
    final inProgress = await _progressRepo.getInProgress(limit: 100);
    final contentProgress = inProgress.where(
      (row) => row['contentId'] == contentId,
    );

    if (contentProgress.isNotEmpty) {
      final episodeId = contentProgress.first['episodeId'] as int;
      final ep = await _episodeRepo.getById(episodeId);
      if (ep != null && ep.fileStatus == FileStatus.ready) return ep;
    }

    // 2. If nothing is in progress, find the next episode after the latest finished one
    Episode? latestFinished;
    for (final ep in allEpisodes) {
      final progress = await _progressRepo.getByEpisodeId(ep.id!);
      if (progress != null && progress.isFinished) {
        if (latestFinished == null || _isAfter(ep, latestFinished)) {
          latestFinished = ep;
        }
      }
    }

    if (latestFinished != null) {
      // Try to find the next available episode after this one
      final currentIndex = allEpisodes.indexOf(latestFinished);
      for (int i = currentIndex + 1; i < allEpisodes.length; i++) {
        if (allEpisodes[i].fileStatus == FileStatus.ready) {
          return allEpisodes[i];
        }
      }
      // If none forward, maybe stay on the last finished one if it's ready
      if (latestFinished.fileStatus == FileStatus.ready) return latestFinished;
    }

    // 3. Default to the first available ready episode
    return readyEpisodes.first;
  }

  /// Saves or updates watch progress for an episode.
  Future<void> saveProgress({
    required int contentId,
    required int episodeId,
    required int positionMs,
    required int durationMs,
  }) async {
    if (durationMs <= 0) return;

    final percentage = positionMs / durationMs;
    final isFinished = percentage > 0.9; // 90% threshold for finished

    final progress = WatchProgress(
      contentId: contentId,
      episodeId: episodeId,
      positionMs: positionMs,
      durationMs: durationMs,
      isFinished: isFinished,
      lastWatchedAt: DateTime.now(),
    );

    await _progressRepo.save(progress);

    // Invalidate providers to refresh UI
    _ref.invalidate(continueWatchingProvider);
    _ref.invalidate(resumeEpisodeProvider(contentId));
    _ref.invalidate(watchProgressProvider(episodeId));
  }

  bool _isAfter(Episode a, Episode b) {
    if ((a.seasonNumber ?? 0) > (b.seasonNumber ?? 0)) return true;
    if ((a.seasonNumber ?? 0) < (b.seasonNumber ?? 0)) return false;
    return (a.episodeNumber ?? 0) > (b.episodeNumber ?? 0);
  }
}
