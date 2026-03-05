class WatchProgress {
  final int? id;
  final int contentId;
  final int? episodeId; // null if it's a movie
  final int progressSeconds; // in seconds
  final bool isFinished;
  final DateTime lastWatchedAt;

  WatchProgress({
    this.id,
    required this.contentId,
    this.episodeId,
    required this.progressSeconds,
    required this.isFinished,
    DateTime? lastWatchedAt,
  }) : lastWatchedAt = lastWatchedAt ?? DateTime.now();

  // Convert to DB row
  Map<String, dynamic> toMap() {
    return {
      'contentId': contentId,
      'episodeId': episodeId,
      'progressSeconds': progressSeconds,
      'isFinished': isFinished ? 1 : 0,
      'lastWatchedAt': lastWatchedAt.toIso8601String(),
    };
  }

  // Create from DB row
  factory WatchProgress.fromMap(Map<String, dynamic> map) {
    return WatchProgress(
      id: map['id'] as int?,
      contentId: map['contentId'] as int,
      episodeId: map['episodeId'] as int?,
      progressSeconds: map['progressSeconds'] != null
          ? map['progressSeconds'] as int
          : 0,
      isFinished: map['isFinished'] == 1,
      lastWatchedAt: map['lastWatchedAt'] != null
          ? DateTime.parse(map['lastWatchedAt'])
          : DateTime.now(),
    );
  }

  // Factory for creating new progress entries
  factory WatchProgress.create({
    required int contentId,
    int? episodeId,
    int progressSeconds = 0,
    bool isFinished = false,
  }) {
    return WatchProgress(
      contentId: contentId,
      episodeId: episodeId,
      progressSeconds: progressSeconds,
      isFinished: isFinished,
      lastWatchedAt: DateTime.now(),
    );
  }

  // Create a modified copy
  WatchProgress copyWith({
    int? id,
    int? contentId,
    int? episodeId,
    int? progressSeconds,
    bool? isFinished,
    DateTime? lastWatchedAt,
  }) {
    return WatchProgress(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      episodeId: episodeId ?? this.episodeId,
      progressSeconds: progressSeconds ?? this.progressSeconds,
      isFinished: isFinished ?? this.isFinished,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
    );
  }
}
