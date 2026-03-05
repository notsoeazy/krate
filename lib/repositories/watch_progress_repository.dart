// watch_progress_repository.dart
import 'package:sqflite/sqflite.dart';
import 'package:krate/database/database_helper.dart';
import 'package:krate/models/app/watch_progress.dart';

class WatchProgressRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Insert new progress or replace existing one (by contentId + episodeId)
  Future<int> insertProgress(WatchProgress progress) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'watch_progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get progress for a content & optional episode
  Future<WatchProgress?> getProgress(int contentId, {int? episodeId}) async {
    final db = await _dbHelper.database;
    final whereClause =
        'contentId = ? AND episodeId ${episodeId == null ? "IS NULL" : "= ?"}';
    final whereArgs = episodeId == null ? [contentId] : [contentId, episodeId];

    final maps = await db.query(
      'watch_progress',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty ? WatchProgress.fromMap(maps.first) : null;
  }

  /// Get all progress records
  Future<List<WatchProgress>> getAllProgress() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'watch_progress',
      orderBy: 'lastWatchedAt DESC',
    );
    return maps.map((map) => WatchProgress.fromMap(map)).toList();
  }

  /// Get all progress for a specific content, ordered by most recently watched
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

  /// Update existing progress (requires id), auto-updates lastWatchedAt
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

  /// Delete progress by id
  Future<int> deleteProgress(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('watch_progress', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all progress for a content (episodes included)
  Future<int> deleteByContent(int contentId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'watch_progress',
      where: 'contentId = ?',
      whereArgs: [contentId],
    );
  }

  /// Reset progress for a specific content & optional episode
  Future<int> resetProgress(int contentId, {int? episodeId}) async {
    final db = await _dbHelper.database;
    final whereClause =
        'contentId = ? AND episodeId ${episodeId == null ? "IS NULL" : "= ?"}';
    final whereArgs = episodeId == null ? [contentId] : [contentId, episodeId];

    return await db.update(
      'watch_progress',
      {
        'progressSeconds': 0,
        'isFinished': 0,
        'lastWatchedAt': DateTime.now().toIso8601String(),
      },
      where: whereClause,
      whereArgs: whereArgs,
    );
  }
}
