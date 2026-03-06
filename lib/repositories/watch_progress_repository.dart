import 'package:sqflite/sqflite.dart';
import 'package:krate/database/database_helper.dart';
import 'package:krate/models/app/content.dart';
import 'package:krate/models/app/watch_progress.dart';

class WatchProgressRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Insert new progress or replace existing one (UNIQUE on episodeId)
  Future<int> insertProgress(WatchProgress progress) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'watch_progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get progress for a specific episode
  Future<WatchProgress?> getProgressByEpisode(int episodeId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'watch_progress',
      where: 'episodeId = ?',
      whereArgs: [episodeId],
      limit: 1,
    );
    return maps.isNotEmpty ? WatchProgress.fromMap(maps.first) : null;
  }

  /// Alias for getProgressByEpisode
  Future<WatchProgress?> getProgress(int episodeId) =>
      getProgressByEpisode(episodeId);

  /// Get all progress records for a content (all episodes)
  Future<List<WatchProgress>> getProgressByContent(int contentId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'watch_progress',
      where: 'contentId = ?',
      whereArgs: [contentId],
      orderBy: 'lastWatchedAt DESC',
    );
    return maps.map((map) => WatchProgress.fromMap(map)).toList();
  }

  /// Get all progress records ordered by most recently watched
  Future<List<WatchProgress>> getAllProgress() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'watch_progress',
      orderBy: 'lastWatchedAt DESC',
    );
    return maps.map((map) => WatchProgress.fromMap(map)).toList();
  }

  /// Update existing progress (requires id), auto-stamps lastWatchedAt
  Future<int> updateProgress(WatchProgress progress) async {
    if (progress.id == null) {
      throw ArgumentError('Cannot update WatchProgress without an id');
    }
    final db = await _dbHelper.database;
    return await db.update(
      'watch_progress',
      {...progress.toMap(), 'lastWatchedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [progress.id],
    );
  }

  /// Save or update progress — upserts based on episodeId
  Future<void> saveProgress({
    required int contentId,
    required int episodeId,
    required int positionMs,
    required bool isFinished,
  }) async {
    final db = await _dbHelper.database;
    await db.insert('watch_progress', {
      'contentId': contentId,
      'episodeId': episodeId,
      'positionMs': positionMs,
      'isFinished': isFinished ? 1 : 0,
      'lastWatchedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Delete progress by id
  Future<int> deleteProgress(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('watch_progress', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all progress for a content (cascades via FK, but explicit for clarity)
  Future<int> deleteByContent(int contentId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'watch_progress',
      where: 'contentId = ?',
      whereArgs: [contentId],
    );
  }

  /// Reset progress to 0 for a specific episode
  Future<int> resetProgress(int episodeId) async {
    final db = await _dbHelper.database;
    return await db.update(
      'watch_progress',
      {
        'positionMs': 0,
        'isFinished': 0,
        'lastWatchedAt': DateTime.now().toIso8601String(),
      },
      where: 'episodeId = ?',
      whereArgs: [episodeId],
    );
  }

  /// Get in-progress items for the "Continue Watching" dashboard section.
  /// Returns a list of Content joined with the last watched episode info.
  /// [limit] defaults to 10.
  Future<List<Map<String, dynamic>>> getInProgress({int limit = 10}) async {
    final db = await _dbHelper.database;
    final results = await db.rawQuery(
      '''
      SELECT
        c.*,
        wp.id        AS progressId,
        wp.episodeId AS episodeId,
        wp.positionMs,
        wp.lastWatchedAt,
        e.seasonNumber,
        e.episodeNumber,
        e.title      AS episodeTitle,
        e.runtime    AS episodeRuntime
      FROM watch_progress wp
      JOIN content c  ON c.id  = wp.contentId
      JOIN episodes e ON e.id  = wp.episodeId
      WHERE wp.isFinished = 0
      ORDER BY wp.lastWatchedAt DESC
      LIMIT ?
      ''',
      [limit],
    );
    return results;
  }

  /// Parse getInProgress results into Content objects
  Future<List<Content>> getInProgressContent({int limit = 10}) async {
    final rows = await getInProgress(limit: limit);
    return rows.map((row) => Content.fromMap(row)).toList();
  }
}
