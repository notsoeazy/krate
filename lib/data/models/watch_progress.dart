/// Tracks the current resume point for a single episode/movie.
///
/// There is at most one row per [episodeId] — movies and episodes are
/// treated symmetrically (movies have a single episode row).
class WatchProgress {
  final int? id;
  final int contentId;
  final int episodeId;

  /// Last playback position in milliseconds.
  final int positionMs;

  /// Duration of the video in milliseconds (cached to compute percentage).
  final int durationMs;

  /// True once the user has passed [kFinishedThreshold].
  final bool isFinished;

  final DateTime lastWatchedAt;

  const WatchProgress({
    this.id,
    required this.contentId,
    required this.episodeId,
    this.positionMs = 0,
    this.durationMs = 0,
    this.isFinished = false,
    required this.lastWatchedAt,
  });

  double get percentage =>
      durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() => {
    'contentId': contentId,
    'episodeId': episodeId,
    'positionMs': positionMs,
    'durationMs': durationMs,
    'isFinished': isFinished ? 1 : 0,
    'lastWatchedAt': lastWatchedAt.toIso8601String(),
  };

  factory WatchProgress.fromMap(Map<String, dynamic> map) => WatchProgress(
    id: map['id'] as int?,
    contentId: map['contentId'] as int,
    episodeId: map['episodeId'] as int,
    positionMs: (map['positionMs'] as int?) ?? 0,
    durationMs: (map['durationMs'] as int?) ?? 0,
    isFinished: map['isFinished'] == 1,
    lastWatchedAt: DateTime.parse(map['lastWatchedAt'] as String),
  );

  WatchProgress copyWith({
    int? id,
    int? contentId,
    int? episodeId,
    int? positionMs,
    int? durationMs,
    bool? isFinished,
    DateTime? lastWatchedAt,
  }) => WatchProgress(
    id: id ?? this.id,
    contentId: contentId ?? this.contentId,
    episodeId: episodeId ?? this.episodeId,
    positionMs: positionMs ?? this.positionMs,
    durationMs: durationMs ?? this.durationMs,
    isFinished: isFinished ?? this.isFinished,
    lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
  );
}
