import 'package:krate/data/database/app_database.dart';
import 'package:krate/data/models/watch_history.dart';

class WatchHistoryRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<void> record(WatchHistory history) async {
    final db = await _db.database;
    await db.insert('watch_history', history.toMap());
  }

  /// Returns all history rows joined with content info, newest first.
  Future<List<Map<String, dynamic>>> getAll({int limit = 100}) async {
    final db = await _db.database;
    return db.rawQuery(
      '''
      SELECT wh.*, c.title, c.contentType, c.localPosterPath, c.podPath,
             e.seasonNumber, e.episodeNumber, e.title AS episodeTitle
      FROM watch_history wh
      JOIN content c ON c.id = wh.contentId
      JOIN episodes e ON e.id = wh.episodeId
      ORDER BY wh.finishedAt DESC
      LIMIT ?
      ''',
      [limit],
    );
  }

  /// Returns the list of content IDs that have been fully watched
  /// (i.e., they have a finished watch_progress entry).
  Future<List<int>> getCompletedContentIds() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT contentId FROM watch_progress
      WHERE isFinished = 1
      ''');
    return rows.map((r) => r['contentId'] as int).toList();
  }

  Future<void> clearAll() async {
    final db = await _db.database;
    await db.delete('watch_history');
  }
}
