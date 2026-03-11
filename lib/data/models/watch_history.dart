class WatchHistory {
  final int? id;
  final int contentId;
  final int episodeId;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int durationWatchedMs;

  const WatchHistory({
    this.id,
    required this.contentId,
    required this.episodeId,
    required this.startedAt,
    required this.finishedAt,
    required this.durationWatchedMs,
  });

  Map<String, dynamic> toMap() => {
    'contentId': contentId,
    'episodeId': episodeId,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt.toIso8601String(),
    'durationWatchedMs': durationWatchedMs,
  };

  factory WatchHistory.fromMap(Map<String, dynamic> map) => WatchHistory(
    id: map['id'] as int?,
    contentId: map['contentId'] as int,
    episodeId: map['episodeId'] as int,
    startedAt: DateTime.parse(map['startedAt'] as String),
    finishedAt: DateTime.parse(map['finishedAt'] as String),
    durationWatchedMs: (map['durationWatchedMs'] as int?) ?? 0,
  );
}
