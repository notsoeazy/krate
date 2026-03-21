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

  // Returns content that is currently being watched but is NOT fully completed.
  // Movies: Have watch progress but not finished.
  // Series: Have at least one finished or in-progress episode, but total finished < totalEpisodes.
  Future<List<Content>> getWatchingContent({int limit = 20}) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT c.*
      FROM content c
      WHERE c.id IN (
        SELECT contentId FROM watch_progress 
        WHERE isFinished = 0 AND positionMs > 0 AND contentId IN (SELECT id FROM content WHERE contentType = 'movie')

        UNION

        SELECT contentId FROM watch_progress wp
        JOIN content c2 ON c2.id = wp.contentId
        WHERE c2.contentType = 'series'
        GROUP BY c2.id
        HAVING SUM(wp.isFinished) < c2.totalEpisodes AND SUM(wp.positionMs) > 0
      )
      ORDER BY (SELECT MAX(lastWatchedAt) FROM watch_progress WHERE contentId = c.id) DESC
      LIMIT ?
      ''',
      [limit],
    );
    return rows.map(Content.fromMap).toList();
  }

  // Returns fully completed content.
  // Movies: The only episode is finished.
  // Series: Count of finished episodes >= totalEpisodes metadata.
  Future<List<Content>> getCompletedContent({int limit = 50}) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      '''
      SELECT c.*
      FROM content c
      WHERE (
        (c.contentType = 'movie' AND EXISTS (
          SELECT 1 FROM watch_progress wp WHERE wp.contentId = c.id AND wp.isFinished = 1
        ))
        OR
        (c.contentType = 'series' AND (
          SELECT SUM(isFinished) FROM watch_progress WHERE contentId = c.id
        ) >= c.totalEpisodes AND c.totalEpisodes > 0)
      )
      ORDER BY (SELECT MAX(lastWatchedAt) FROM watch_progress WHERE contentId = c.id) DESC
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

  Future<void> markEpisodesFinished(List<int> episodeIds, int contentId) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      for (final id in episodeIds) {
        // We use insert with replace to ensure progress entry exists if it didn't before
        await txn.insert(
          'watch_progress',
          {
            'episodeId': id,
            'contentId': contentId,
            'isFinished': 1,
            'positionMs': 0, // We don't know duration, so 0 is fine since isFinished is 1
            'durationMs': 0,
            'lastWatchedAt': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> clearEpisodesProgress(List<int> episodeIds) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final id in episodeIds) {
        await txn.delete(
          'watch_progress',
          where: 'episodeId = ?',
          whereArgs: [id],
        );
      }
    });
  }


  Future<void> clearSeriesProgress(int contentId) async {
    final db = await _db.database;
    await db.delete(
      'watch_progress',
      where: 'contentId = ?',
      whereArgs: [contentId],
    );
  }

  Future<void> markSeasonsFinished(int contentId, List<int> seasonNumbers) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    await db.transaction((txn) async {
      for (final sn in seasonNumbers) {
        await txn.execute(
          '''
          INSERT OR REPLACE INTO watch_progress (episodeId, contentId, isFinished, positionMs, durationMs, lastWatchedAt)
          SELECT id, contentId, 1, 0, 0, ? FROM episodes WHERE contentId = ? AND seasonNumber = ?
          ''',
          [now, contentId, sn],
        );
      }
    });
  }

  Future<void> clearSeasonsProgress(int contentId, List<int> seasonNumbers) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (final sn in seasonNumbers) {
        await txn.delete(
          'watch_progress',
          where: 'contentId = ? AND episodeId IN (SELECT id FROM episodes WHERE contentId = ? AND seasonNumber = ?)',
          whereArgs: [contentId, contentId, sn],
        );
      }
    });
  }

  Future<void> markSeasonFinished(int contentId, int seasonNumber) async {
    await markSeasonsFinished(contentId, [seasonNumber]);
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
