import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/data/models/watch_progress.dart';
import 'package:krate/data/repositories/episode_repository.dart';
import 'package:krate/data/repositories/watch_history_repository.dart';
import 'package:krate/data/repositories/watch_progress_repository.dart';
import 'package:krate/providers/providers.dart';
import 'package:flutter/foundation.dart';

class WatchProgressService {
  final WatchProgressRepository _progressRepo;
  final EpisodeRepository _episodeRepo;
  final WatchHistoryRepository _historyRepo;
  final Ref _ref;

  WatchProgressService({
    required WatchProgressRepository progressRepo,
    required EpisodeRepository episodeRepo,
    required WatchHistoryRepository historyRepo,
    required Ref ref,
  }) : _progressRepo = progressRepo,
       _episodeRepo = episodeRepo,
       _historyRepo = historyRepo,
       _ref = ref;

  // Determines the best episode to resume for a given content item.
  Future<Episode?> getResumeEpisode(int contentId) async {
    final allEpisodes = await _episodeRepo.getByContentId(contentId);
    if (allEpisodes.isEmpty) return null;

    final readyEpisodes = allEpisodes
        .where((ep) => ep.fileStatus == FileStatus.ready)
        .toList();

    // Check for most recently watched progress for this content
    final inProgress = await _progressRepo.getInProgress(limit: 100);
    final contentProgress = inProgress.where(
      (row) => row['contentId'] == contentId,
    );

    if (contentProgress.isNotEmpty) {
      final row = contentProgress.first;
      final episodeId = row['episodeId'] as int;
      final isFinished = (row['isFinished'] as int) == 1;

      final ep = await _episodeRepo.getById(episodeId);
      if (ep != null) {
        if (!isFinished) {
          // If current episode is not finished, resume it (even if file is missing, UI handles it)
          return ep;
        } else {
          // If finished, try to find the next one
          final nextEp = await _episodeRepo.getNextEpisode(ep);
          if (nextEp != null) return nextEp;

          // If no next episode, this content is finished.
          // Fall back to the first episode so the play button stays (Restart)
          return allEpisodes.first;
        }
      }
    }

    // If nothing in progress or no matches, find the next episode after the latest finished one
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
      final nextEp = await _episodeRepo.getNextEpisode(latestFinished);
      if (nextEp != null) return nextEp;
    }

    // Default to the first available ready episode if possible, otherwise first metadata
    return readyEpisodes.isNotEmpty ? readyEpisodes.first : allEpisodes.first;
  }

  // Saves or updates watch progress for an episode.
  Future<void> saveProgress({
    required int contentId,
    required int episodeId,
    required int positionMs,
    required int durationMs,
  }) async {
    if (durationMs <= 0) return;

    final percentage = positionMs / durationMs;
    final isFinished = percentage > kFinishedThreshold;

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

  Future<void> markEpisodesFinished(List<int> episodeIds, int contentId) async {
    for (final id in episodeIds) {
      debugPrint('[WatchProgressService] Marking episode $id as finished');
    }
    await _progressRepo.markEpisodesFinished(episodeIds, contentId);
    _invalidateContent(contentId, episodeIds: episodeIds);
  }

  Future<void> clearEpisodesProgress(
    List<int> episodeIds,
    int contentId,
  ) async {
    for (final id in episodeIds) {
      debugPrint('[WatchProgressService] Clearing progress for episode $id');
    }
    await _progressRepo.clearEpisodesProgress(episodeIds);
    _invalidateContent(contentId, episodeIds: episodeIds);
  }

  Future<List<WatchProgress>> markSeasonFinished(int contentId, int seasonNumber) async {
    return await markSeasonsFinished(contentId, [seasonNumber]);
  }

  Future<List<WatchProgress>> markSeasonsFinished(
    int contentId,
    List<int> seasonNumbers,
  ) async {
    debugPrint(
      '[WatchProgressService] Marking seasons $seasonNumbers as finished for content $contentId',
    );
    final snapshot = await _progressRepo.getProgressForContent(contentId);
    await _progressRepo.markSeasonsFinished(contentId, seasonNumbers);
    _invalidateContent(contentId);
    return snapshot;
  }

  Future<void> clearSeasonsProgress(
    int contentId,
    List<int> seasonNumbers,
  ) async {
    debugPrint(
      '[WatchProgressService] Clearing progress for seasons $seasonNumbers for content $contentId',
    );
    await _progressRepo.clearSeasonsProgress(contentId, seasonNumbers);
    _invalidateContent(contentId);
  }

  Future<List<WatchProgress>> clearSeriesProgress(int contentId) async {
    debugPrint(
      '[WatchProgressService] Clearing ALL progress and history for content $contentId',
    );
    final snapshot = await _progressRepo.getProgressForContent(contentId);
    await _progressRepo.clearSeriesProgress(contentId);
    await _historyRepo.deleteByContentId(contentId);
    _invalidateContent(contentId);
    return snapshot;
  }

  Future<void> restoreSnapshot(int contentId, List<WatchProgress> snapshot) async {
    debugPrint('[WatchProgressService] Restoring progress snapshot for content $contentId');
    await _progressRepo.clearSeriesProgress(contentId); // Clear any new progress before restoring old
    await _progressRepo.restoreProgress(snapshot);
    _invalidateContent(contentId);
  }

  void _invalidateContent(int contentId, {List<int>? episodeIds}) async {
    _ref.invalidate(continueWatchingProvider);
    _ref.invalidate(watchingContentProvider);
    _ref.invalidate(completedContentProvider);
    _ref.invalidate(resumeEpisodeProvider(contentId));
    _ref.invalidate(contentEpisodesProvider(contentId));

    // If we have specific IDs, invalidate them instantly
    if (episodeIds != null) {
      for (final id in episodeIds) {
        _ref.invalidate(watchProgressProvider(id));
      }
    } else {
      // Otherwise, get all episodes for this content and invalidate them
      final eps = await _episodeRepo.getByContentId(contentId);
      for (final ep in eps) {
        if (ep.id != null) {
          _ref.invalidate(watchProgressProvider(ep.id!));
        }
      }
    }
  }
}
