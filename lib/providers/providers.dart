import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krate/utils/constants.dart';
import 'package:krate/data/models/content.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/data/models/import_job.dart';
import 'package:krate/data/models/watch_progress.dart';
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
import 'package:krate/services/watch_progress_service.dart';

// UI State Providers
final shellTabIndexProvider = StateProvider<int>((ref) => 0);

/// Which tab the Library screen should show: 0 = Movies, 1 = Series.
final libraryTabProvider = StateProvider<int>((ref) => 0);

// Infrastructure singletons
final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

// Repositories
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

// Services
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

final watchProgressServiceProvider = Provider<WatchProgressService>((ref) {
  return WatchProgressService(
    progressRepo: ref.read(watchProgressRepoProvider),
    episodeRepo: ref.read(episodeRepoProvider),
    ref: ref,
  );
});

// Vault status (checked on startup)
final vaultStatusProvider = FutureProvider<VaultStatus>((ref) {
  return ref.read(storageServiceProvider).checkIntegrity();
});

// Import Jobs globally managed list of in-flight/recent imports
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
      _ref.read(importToastProvider.notifier).show(job);
    }
  }

  void _invalidateLibrary() {
    _ref.invalidate(moviesProvider);
    _ref.invalidate(seriesProvider);
    _ref.invalidate(recentMoviesProvider);
    _ref.invalidate(recentSeriesProvider);
  }

  /// Invalidates episode + content providers for [contentId] so any watching
  /// screen (MediaDetailsScreen, MediaManagementScreen) refreshes immediately.
  void _invalidateContentData(int contentId) {
    _ref.invalidate(contentEpisodesProvider(contentId));
    _ref.invalidate(contentProvider(contentId));
    _ref.invalidate(resumeEpisodeProvider(contentId));
  }

  /// Returns the number of currently active (queued or running) jobs.
  int get activeCount => state.where((j) => j.isActive).length;

  Future<void> importMovie({
    required ImportService service,
    required Content content,
    required String sourceFilePath,
  }) async {
    await service.scoutMovie(
      content: content,
      sourceFilePath: sourceFilePath,
      onUpdate: _update,
    );
    if (content.id != null) _invalidateContentData(content.id!);
    _invalidateLibrary();
  }

  Future<void> importSeries({
    required ImportService service,
    required Content content,
    required Map<int, Map<int, String>> episodeFiles,
  }) async {
    await service.scoutSeries(
      content: content,
      episodeFiles: episodeFiles,
      onUpdate: _update,
    );
    if (content.id != null) _invalidateContentData(content.id!);
    _invalidateLibrary();
  }

  Future<void> linkEpisodes({
    required ImportService service,
    required Content content,
    required Map<int, String> episodeFiles, // episodeId -> filePath
  }) async {
    await service.linkEpisodes(
      content: content,
      episodeFiles: episodeFiles,
      onUpdate: _update,
    );
    // Invalidate so MediaDetailsScreen reflects the newly linked files immediately.
    if (content.id != null) _invalidateContentData(content.id!);
  }

  Future<void> rescanMovie({
    required ImportService service,
    required Content content,
  }) async {
    await service.rescanMovie(content: content, onUpdate: _update);
    if (content.id != null) _invalidateContentData(content.id!);
  }

  Future<void> rescanSeries({
    required ImportService service,
    required Content content,
  }) async {
    await service.rescanSeries(content: content, onUpdate: _update);
    if (content.id != null) _invalidateContentData(content.id!);
  }

  Future<void> deleteEpisodes({
    required ImportService service,
    required Content content,
    required List<Episode> episodes,
  }) async {
    await service.deleteEpisodesBatch(content: content, episodes: episodes);
    if (content.id != null) _invalidateContentData(content.id!);
    // Clear the episode from Continue Watching and refresh library card badges.
    _ref.invalidate(continueWatchingProvider);
    _invalidateLibrary();
  }

  void dismissCompleted() {
    state = state.where((j) => j.isActive).toList();
  }
}

final importJobsProvider =
    StateNotifierProvider<ImportJobsNotifier, List<ImportJob>>(
      (ref) => ImportJobsNotifier(ref),
    );

// Import Toast manages a single temporary toast for job completion/error
class ImportToastNotifier extends StateNotifier<ImportJob?> {
  ImportToastNotifier() : super(null);

  void show(ImportJob job) {
    state = job;
  }

  void dismiss() {
    state = null;
  }
}

final importToastProvider =
    StateNotifierProvider<ImportToastNotifier, ImportJob?>(
      (ref) => ImportToastNotifier(),
    );

// Scanner state
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

// Library data providers (async, cached per filter)
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

/// Watches episodes for a content item. Not autoDispose — cached in memory so
/// tab switching is instant. Explicitly invalidated after any mutation.
final contentEpisodesProvider = FutureProvider.family<List<Episode>, int>((
  ref,
  contentId,
) {
  return ref.read(episodeRepoProvider).getByContentId(contentId);
});

/// Filters cached episodes for a single season. Not autoDispose — cached
/// alongside contentEpisodesProvider and only refreshed after mutations.
final mergedEpisodesProvider =
    FutureProvider.family<List<Episode>, ({int contentId, int seasonNumber})>((
      ref,
      arg,
    ) async {
      final all = await ref.watch(
        contentEpisodesProvider(arg.contentId).future,
      );
      return all.where((e) => e.seasonNumber == arg.seasonNumber).toList();
    });

/// Determines the best episode to resume for a given content item.
final resumeEpisodeProvider = FutureProvider.family.autoDispose<Episode?, int>((
  ref,
  contentId,
) {
  return ref.read(watchProgressServiceProvider).getResumeEpisode(contentId);
});

/// Watches progress for a specific episode.
final watchProgressProvider = FutureProvider.family
    .autoDispose<WatchProgress?, int>((ref, episodeId) {
      return ref.read(watchProgressRepoProvider).getByEpisodeId(episodeId);
    });

/// Returns episode count info for a series used to render the progress badge
/// on [MediaCard]. Derived from [contentEpisodesProvider].
/// Record: {total: int, available: int}.
final contentEpisodeCountProvider =
    FutureProvider.family<({int total, int available}), int>((
      ref,
      contentId,
    ) async {
      final eps = await ref.watch(contentEpisodesProvider(contentId).future);
      return (total: eps.length, available: eps.where((e) => e.hasFile).length);
    });

// Media Management per-screen scoped state
/// The exclusive interaction mode of [MediaManagementScreen].
enum ManagementMode {
  /// Default — tap an episode icon to stage a file for import.
  importStaging,

  /// Delete-checkbox mode — only episodes with media are selectable.
  deleteSelection,

  /// A job is running; all user interaction is locked.
  jobRunning,
}

/// One staged import entry: an episode + the local file path chosen for it.
@immutable
class StagedFile {
  final int episodeId;
  final String path;

  /// `true` when the episode already has a file — this will be a replace op.
  final bool isReplace;

  const StagedFile({
    required this.episodeId,
    required this.path,
    required this.isReplace,
  });
}

/// Immutable state snapshot for [MediaManagementScreen].
@immutable
class MediaManagementState {
  final ManagementMode mode;

  /// episodeId → staged file. Only populated in [ManagementMode.importStaging].
  final Map<int, StagedFile> stagedFiles;

  /// Episode IDs selected for deletion. Only populated in [ManagementMode.deleteSelection].
  final Set<int> deleteSelections;

  /// `true` while the OS file-picker dialog is open.
  final bool isPickerOpen;

  const MediaManagementState({
    this.mode = ManagementMode.importStaging,
    this.stagedFiles = const {},
    this.deleteSelections = const {},
    this.isPickerOpen = false,
  });

  // Derived guards used by the UI
  bool get hasJobRunning => mode == ManagementMode.jobRunning;
  bool get isDeleteMode => mode == ManagementMode.deleteSelection;

  /// Scan is only allowed when idle with no files staged and picker closed.
  bool get canScan =>
      mode == ManagementMode.importStaging &&
      stagedFiles.isEmpty &&
      !isPickerOpen;

  /// Switching to delete mode requires the same idle condition.
  bool get canSwitchToDelete => canScan;

  bool get importButtonEnabled => stagedFiles.isNotEmpty && !hasJobRunning;
  bool get deleteButtonEnabled => deleteSelections.isNotEmpty && !hasJobRunning;

  MediaManagementState copyWith({
    ManagementMode? mode,
    Map<int, StagedFile>? stagedFiles,
    Set<int>? deleteSelections,
    bool? isPickerOpen,
  }) => MediaManagementState(
    mode: mode ?? this.mode,
    stagedFiles: stagedFiles ?? this.stagedFiles,
    deleteSelections: deleteSelections ?? this.deleteSelections,
    isPickerOpen: isPickerOpen ?? this.isPickerOpen,
  );
}

class MediaManagementNotifier extends StateNotifier<MediaManagementState> {
  MediaManagementNotifier() : super(const MediaManagementState());

  // File picker
  Future<void> pickFile({
    required int episodeId,
    required bool episodeHasFile,
  }) async {
    if (state.isPickerOpen || state.hasJobRunning) return;
    state = state.copyWith(isPickerOpen: true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mkv', 'avi', 'mov', 'wmv'],
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        state = state.copyWith(
          stagedFiles: {
            ...state.stagedFiles,
            episodeId: StagedFile(
              episodeId: episodeId,
              path: path,
              isReplace: episodeHasFile,
            ),
          },
        );
      }
    } finally {
      state = state.copyWith(isPickerOpen: false);
    }
  }

  void removeStaged(int episodeId) {
    final updated = Map<int, StagedFile>.from(state.stagedFiles)
      ..remove(episodeId);
    state = state.copyWith(stagedFiles: updated);
  }

  // Delete mode
  void enterDeleteMode() {
    if (!state.canSwitchToDelete) return;
    state = state.copyWith(
      mode: ManagementMode.deleteSelection,
      stagedFiles: const {},
      deleteSelections: const {},
    );
  }

  void exitDeleteMode() {
    if (state.hasJobRunning) return;
    state = state.copyWith(
      mode: ManagementMode.importStaging,
      deleteSelections: const {},
    );
  }

  void toggleDeleteSelection(int episodeId, {required bool selected}) {
    if (!state.isDeleteMode) return;
    final updated = Set<int>.from(state.deleteSelections);
    selected ? updated.add(episodeId) : updated.remove(episodeId);
    state = state.copyWith(deleteSelections: updated);
  }

  // Job lifecycle
  void markJobRunning() {
    state = state.copyWith(mode: ManagementMode.jobRunning);
  }

  /// Resets to clean import-staging state after a foreground job finishes.
  void markJobDone() {
    state = state.copyWith(
      mode: ManagementMode.importStaging,
      stagedFiles: const {},
      deleteSelections: const {},
    );
  }
}

/// Scoped per content ID. Auto-disposed when the screen is popped.
final mediaManagementProvider = StateNotifierProvider.autoDispose
    .family<MediaManagementNotifier, MediaManagementState, int>(
      (ref, contentId) => MediaManagementNotifier(),
    );
