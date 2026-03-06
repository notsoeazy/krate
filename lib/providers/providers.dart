import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/core/constants.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/data/models/import_job.dart';
import 'package:krate/data/repositories/content_repository.dart';
import 'package:krate/data/repositories/episode_repository.dart';
import 'package:krate/data/repositories/watch_history_repository.dart';
import 'package:krate/data/repositories/watch_progress_repository.dart';
import 'package:krate/services/artwork_service.dart';
import 'package:krate/services/import_service.dart';
import 'package:krate/services/metadata_service.dart';
import 'package:krate/services/scanner_service.dart';
import 'package:krate/services/storage_service.dart';
import 'package:krate/services/tmdb_service.dart';

// ---------------------------------------------------------------------------
// Infrastructure — singletons
// ---------------------------------------------------------------------------

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

final contentRepoProvider = Provider<ContentRepository>(
  (ref) => ContentRepository(),
);

final episodeRepoProvider = Provider<EpisodeRepository>(
  (ref) => EpisodeRepository(),
);

final watchProgressRepoProvider = Provider<WatchProgressRepository>(
  (ref) => WatchProgressRepository(),
);

final watchHistoryRepoProvider = Provider<WatchHistoryRepository>(
  (ref) => WatchHistoryRepository(),
);

// ---------------------------------------------------------------------------
// Services
// ---------------------------------------------------------------------------

final tmdbServiceProvider = Provider<TMDBService>((ref) => TMDBService());

final artworkServiceProvider = Provider<ArtworkService>(
  (ref) => ArtworkService(),
);

final metadataServiceProvider = Provider<MetadataService>(
  (ref) => MetadataService(),
);

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(
    contentRepo: ref.read(contentRepoProvider),
    episodeRepo: ref.read(episodeRepoProvider),
    artworkService: ref.read(artworkServiceProvider),
    metadataService: ref.read(metadataServiceProvider),
    storageService: ref.read(storageServiceProvider),
    tmdbService: ref.read(tmdbServiceProvider),
  );
});

final scannerServiceProvider = Provider<ScannerService>((ref) {
  return ScannerService(
    contentRepo: ref.read(contentRepoProvider),
    episodeRepo: ref.read(episodeRepoProvider),
    metadataService: ref.read(metadataServiceProvider),
    storageService: ref.read(storageServiceProvider),
  );
});

// ---------------------------------------------------------------------------
// Vault status (checked on startup)
// ---------------------------------------------------------------------------

final vaultStatusProvider = FutureProvider<VaultStatus>((ref) {
  return ref.read(storageServiceProvider).checkIntegrity();
});

// ---------------------------------------------------------------------------
// Import Jobs — globally managed list of in-flight/recent imports
// ---------------------------------------------------------------------------

class ImportJobsNotifier extends StateNotifier<List<ImportJob>> {
  final Ref _ref;
  ImportJobsNotifier(this._ref) : super([]);

  void _update(ImportJob job) {
    final index = state.indexWhere((j) => j.id == job.id);
    if (index == -1) {
      state = [job, ...state];
    } else {
      final updated = [...state];
      updated[index] = job;
      state = updated;
    }

    // If job just finished (Done or Error), invalidate content providers to refresh UI
    if (job.status == ImportJobStatus.done ||
        job.status == ImportJobStatus.error) {
      _invalidateLibrary();
    }
  }

  void _invalidateLibrary() {
    _ref.invalidate(moviesProvider);
    _ref.invalidate(seriesProvider);
    _ref.invalidate(recentMoviesProvider);
    _ref.invalidate(recentSeriesProvider);
  }

  /// Returns the number of currently active (queued or running) jobs.
  int get activeCount => state.where((j) => j.isActive).length;

  Future<void> importMovie({
    required ImportService service,
    required Content content,
    required String sourceFilePath,
  }) async {
    await service.importMovie(
      content: content,
      sourceFilePath: sourceFilePath,
      onUpdate: _update,
    );
  }

  Future<void> importSeries({
    required ImportService service,
    required Content content,
    required Map<int, Map<int, String>> episodeFiles,
  }) async {
    await service.importSeries(
      content: content,
      episodeFiles: episodeFiles,
      onUpdate: _update,
    );
  }

  void dismissCompleted() {
    state = state.where((j) => j.isActive).toList();
  }
}

final importJobsProvider =
    StateNotifierProvider<ImportJobsNotifier, List<ImportJob>>(
      (ref) => ImportJobsNotifier(ref),
    );

// ---------------------------------------------------------------------------
// Scanner state
// ---------------------------------------------------------------------------

class ScannerNotifier
    extends StateNotifier<({bool isScanning, double progress, String status})> {
  final ScannerService _scanner;
  final Ref _ref;

  ScannerNotifier(this._scanner, this._ref)
    : super((isScanning: false, progress: 0.0, status: ''));

  Future<void> scan() async {
    if (state.isScanning) return;
    await _scanner.scan(
      onProgress: (p) =>
          state = (isScanning: true, progress: p, status: state.status),
      onStatus: (s) => state = (
        isScanning: state.isScanning,
        progress: state.progress,
        status: s,
      ),
    );
    state = (isScanning: false, progress: 1.0, status: 'Scan complete');

    // Invalidate library after scan
    _ref.invalidate(moviesProvider);
    _ref.invalidate(seriesProvider);
  }
}

final scannerProvider =
    StateNotifierProvider<
      ScannerNotifier,
      ({bool isScanning, double progress, String status})
    >((ref) => ScannerNotifier(ref.read(scannerServiceProvider), ref));

// ---------------------------------------------------------------------------
// Library data providers (async, cached per filter)
// ---------------------------------------------------------------------------

final moviesProvider = FutureProvider.autoDispose<List<Content>>((ref) {
  return ref.read(contentRepoProvider).getAll(type: ContentType.movie);
});

final seriesProvider = FutureProvider.autoDispose<List<Content>>((ref) {
  return ref.read(contentRepoProvider).getAll(type: ContentType.series);
});

final recentMoviesProvider = FutureProvider.autoDispose<List<Content>>((ref) {
  return ref
      .read(contentRepoProvider)
      .getRecentlyAdded(type: ContentType.movie, limit: 10);
});

final recentSeriesProvider = FutureProvider.autoDispose<List<Content>>((ref) {
  return ref
      .read(contentRepoProvider)
      .getRecentlyAdded(type: ContentType.series, limit: 10);
});

final continueWatchingProvider = FutureProvider.autoDispose<List<Content>>((
  ref,
) {
  return ref.read(watchProgressRepoProvider).getInProgressContent(limit: 10);
});

/// Watches a specific content item reactively.
final contentProvider = FutureProvider.family.autoDispose<Content?, int>((
  ref,
  id,
) {
  return ref.read(contentRepoProvider).getById(id);
});

/// Watches episodes for a content item.
final contentEpisodesProvider = FutureProvider.family
    .autoDispose<List<Episode>, int>((ref, contentId) {
      return ref.read(episodeRepoProvider).getByContentId(contentId);
    });

/// Fetches all episodes for a season from TMDB and merges with local records.
final mergedEpisodesProvider = FutureProvider.family
    .autoDispose<List<Episode>, ({int contentId, int seasonNumber})>((
      ref,
      arg,
    ) async {
      final repo = ref.read(episodeRepoProvider);
      // Online registration phase in ImportService ensures all metadata is local.
      final all = await repo.getByContentId(arg.contentId);
      return all.where((e) => e.seasonNumber == arg.seasonNumber).toList();
    });
