import 'package:sqflite/sqflite.dart';
import 'package:krate/data/database/app_database.dart';
import 'package:krate/data/models/watch_progress.dart';
import 'package:krate/data/models/content.dart';

class WatchProgressRepository {
  final AppDatabase _db = AppDatabase.instance;

  // Upsert progress for a given episode.
  Future<void> save(WatchProgress progress) async {
    final db = await _db.database;
    await db.insert('watch_progress', {
      ...progress.toMap(),
      'lastWatchedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<WatchProgress?> getByEpisodeId(int episodeId) async {
    final db = await _db.database;
    final rows = await db.query(
      'watch_progress',
      where: 'episodeId = ?',
      whereArgs: [episodeId],
      limit: 1,
    );
    return rows.isEmpty ? null : WatchProgress.fromMap(rows.first);
  }

  // Returns all content IDs that have unfinished progress, ordered by
  // most recently watched. Used to populate "Continue Watching".
  Future<List<Map<String, dynamic>>> getInProgress({int limit = 20}) async {
    final db = await _db.database;
    return db.rawQuery(
      '''
      SELECT wp.*, c.title, c.contentType, c.localPosterPath,
             c.localBackdropPath, c.tmdbPosterPath, c.podPath
      FROM watch_progress wp
      JOIN content c ON c.id = wp.contentId
      WHERE wp.isFinished = 0 AND wp.positionMs > 0
      ORDER BY wp.lastWatchedAt DESC
      LIMIT ?
      ''',
      [limit],
    );
  }

  // Returns [Content] objects with in-progress episodes, joined with
  // basic watch info for display in the Continue Watching row.
  Future<List<Content>> getInProgressContent({int limit = 10}) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT DISTINCT c.*
      FROM watch_progress wp
      JOIN content c ON c.id = wp.contentId
      WHERE wp.positionMs > 0
      ORDER BY wp.lastWatchedAt DESC
      LIMIT ?
      ''',
      [limit],
    );
    return rows.map(Content.fromMap).toList();
  }

  Future<void> markFinished(int episodeId) async {
    final db = await _db.database;
    await db.update(
      'watch_progress',
      {'isFinished': 1, 'lastWatchedAt': DateTime.now().toIso8601String()},
      where: 'episodeId = ?',
      whereArgs: [episodeId],
    );
  }

  Future<void> clearForEpisode(int episodeId) async {
    final db = await _db.database;
    await db.delete(
      'watch_progress',
      where: 'episodeId = ?',
      whereArgs: [episodeId],
    );
  }
}
