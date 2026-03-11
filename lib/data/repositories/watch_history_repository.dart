import 'package:krate/data/database/app_database.dart';
import 'package:krate/data/models/watch_history.dart';

class WatchHistoryRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<void> record(WatchHistory history) async {
    final db = await _db.database;

    // We only want ONE history row per Movie or Series.
    final existing = await db.query(
      'watch_history',
      where: 'contentId = ?',
      whereArgs: [history.contentId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      final oldDuration = existing.first['durationWatchedMs'] as int? ?? 0;

      await db.update(
        'watch_history',
        {
          'episodeId':
              history.episodeId, // Always update to the latest episode watched!
          'startedAt': history.startedAt.toIso8601String(),
          'finishedAt': history.finishedAt.toIso8601String(),
          'durationWatchedMs': oldDuration + history.durationWatchedMs,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } else {
      await db.insert('watch_history', history.toMap());
    }
  }

  /// Returns all history rows joined with content info, newest first.
  /// Groups by episodeId to ensure we only show the most recent watch session
  /// for a given episode/movie, preventing duplicates in the UI.
  Future<List<Map<String, dynamic>>> getAll({int limit = 100}) async {
    final db = await _db.database;
    return db.rawQuery(
      '''
      SELECT wh.*, c.title, c.contentType, c.localPosterPath, c.podPath,
             e.seasonNumber, e.episodeNumber, e.title AS episodeTitle
      FROM watch_history wh
      JOIN content c ON c.id = wh.contentId
      JOIN episodes e ON e.id = wh.episodeId
      GROUP BY wh.episodeId
      ORDER BY MAX(wh.finishedAt) DESC
      LIMIT ?
      ''',
      [limit],
    );
  }

  /// Returns the list of content IDs that have been fully watched
  Future<List<int>> getCompletedContentIds() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT contentId FROM watch_progress
      WHERE isFinished = 1
      GROUP BY contentId
      ORDER BY MAX(lastWatchedAt) DESC
      ''');
    return rows.map((r) => r['contentId'] as int).toList();
  }

  Future<void> clearAll() async {
    final db = await _db.database;
    await db.delete('watch_history');
  }
}
