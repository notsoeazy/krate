import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/app/watch_progress.dart';

class WatchProgressRepository {
  final dbHelper = DatabaseHelper();

  /// Insert new progress or replace existing one
  Future<int> insertProgress(WatchProgress progress) async {
    final db = await dbHelper.database;
    return await db.insert(
      'watch_progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get progress for a content & optional episode
  Future<WatchProgress?> getProgress(int contentId, {int? episodeId}) async {
    final db = await dbHelper.database;

    final whereClause =
        'contentId = ? AND episodeId ${episodeId == null ? "IS NULL" : "= ?"}';
    final whereArgs = episodeId == null ? [contentId] : [contentId, episodeId];

    final maps = await db.query(
      'watch_progress',
      where: whereClause,
      whereArgs: whereArgs,
      limit: 1,
    );

    if (maps.isNotEmpty) return WatchProgress.fromMap(maps.first);
    return null;
  }

  /// Get all progress records
  Future<List<WatchProgress>> getAllProgress() async {
    final db = await dbHelper.database;
    final maps = await db.query('watch_progress');
    return maps.map((map) => WatchProgress.fromMap(map)).toList();
  }

  /// Get all progress for a specific content
  Future<List<WatchProgress>> getProgressByContent(int contentId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'watch_progress',
      where: 'contentId = ?',
      whereArgs: [contentId],
      orderBy: 'lastWatchedAt DESC',
    );
    return maps.map((map) => WatchProgress.fromMap(map)).toList();
  }

  /// Update existing progress (requires id)
  Future<int> updateProgress(WatchProgress progress) async {
    if (progress.id == null) {
      throw ArgumentError('Cannot update WatchProgress without an id');
    }
    final db = await dbHelper.database;
    return await db.update(
      'watch_progress',
      progress.toMap(),
      where: 'id = ?',
      whereArgs: [progress.id],
    );
  }

  /// Delete progress by id
  Future<int> deleteProgress(int id) async {
    final db = await dbHelper.database;
    return await db.delete('watch_progress', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all progress for a content (cascades episode progress)
  Future<int> deleteByContent(int contentId) async {
    final db = await dbHelper.database;
    return await db.delete(
      'watch_progress',
      where: 'contentId = ?',
      whereArgs: [contentId],
    );
  }
}
