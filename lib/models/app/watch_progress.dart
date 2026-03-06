class WatchProgress {
  final int? id;
  final int contentId;
  final int episodeId; // always set — movies have a single episode row
  final int positionMs; // playback position in milliseconds (matches media_kit)
  final bool isFinished;
  final DateTime lastWatchedAt;

  WatchProgress({
    this.id,
    required this.contentId,
    required this.episodeId,
    required this.positionMs,
    required this.isFinished,
    DateTime? lastWatchedAt,
  }) : lastWatchedAt = lastWatchedAt ?? DateTime.now();

  // Convert to DB row
  Map<String, dynamic> toMap() {
    return {
      'contentId': contentId,
      'episodeId': episodeId,
      'positionMs': positionMs,
      'isFinished': isFinished ? 1 : 0,
      'lastWatchedAt': lastWatchedAt.toIso8601String(),
    };
  }

  // Create from DB row
  factory WatchProgress.fromMap(Map<String, dynamic> map) {
    return WatchProgress(
      id: map['id'] as int?,
      contentId: map['contentId'] as int,
      episodeId: map['episodeId'] as int,
      positionMs: (map['positionMs'] as int?) ?? 0,
      isFinished: map['isFinished'] == 1,
      lastWatchedAt: map['lastWatchedAt'] != null
          ? DateTime.parse(map['lastWatchedAt'])
          : DateTime.now(),
    );
  }

  // Factory for creating new progress entries
  factory WatchProgress.create({
    required int contentId,
    required int episodeId,
    int positionMs = 0,
    bool isFinished = false,
  }) {
    return WatchProgress(
      contentId: contentId,
      episodeId: episodeId,
      positionMs: positionMs,
      isFinished: isFinished,
      lastWatchedAt: DateTime.now(),
    );
  }

  WatchProgress copyWith({
    int? id,
    int? contentId,
    int? episodeId,
    int? positionMs,
    bool? isFinished,
    DateTime? lastWatchedAt,
  }) {
    return WatchProgress(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      episodeId: episodeId ?? this.episodeId,
      positionMs: positionMs ?? this.positionMs,
      isFinished: isFinished ?? this.isFinished,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
    );
  }
}
