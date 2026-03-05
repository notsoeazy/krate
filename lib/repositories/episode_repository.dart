import 'package:sqflite/sqflite.dart';
import 'package:krate/database/database_helper.dart';
import 'package:krate/models/app/episode.dart';

class EpisodeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Insert new episode or replace if UNIQUE constraint is violated
  Future<int> insertEpisode(Episode episode) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'episodes',
      episode.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update existing episode by local ID, auto-updates updatedAt
  Future<int> updateEpisode(Episode episode) async {
    if (episode.id == null) {
      throw ArgumentError('Cannot update episode without local id');
    }
    final db = await _dbHelper.database;
    return await db.update(
      'episodes',
      {...episode.toMap(), 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [episode.id],
    );
  }

  /// Delete episode by local ID
  Future<int> deleteEpisode(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('episodes', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all episodes for a content, ordered by season & episode
  Future<List<Episode>> getEpisodesByContentId(int contentId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'episodes',
      where: 'contentId = ?',
      whereArgs: [contentId],
      orderBy: 'seasonNumber ASC, episodeNumber ASC',
    );
    return maps.map((map) => Episode.fromMap(map)).toList();
  }

  /// Get all episodes for a specific season
  Future<List<Episode>> getEpisodesBySeason(
    int contentId,
    int seasonNumber,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'episodes',
      where: 'contentId = ? AND seasonNumber = ?',
      whereArgs: [contentId, seasonNumber],
      orderBy: 'episodeNumber ASC',
    );
    return maps.map((map) => Episode.fromMap(map)).toList();
  }

  /// Get a single episode by local ID
  Future<Episode?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'episodes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? Episode.fromMap(maps.first) : null;
  }

  /// Get a single episode by contentId + seasonNumber + episodeNumber
  Future<Episode?> getEpisode(
    int contentId,
    int seasonNumber,
    int episodeNumber,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'episodes',
      where: 'contentId = ? AND seasonNumber = ? AND episodeNumber = ?',
      whereArgs: [contentId, seasonNumber, episodeNumber],
      limit: 1,
    );
    return maps.isNotEmpty ? Episode.fromMap(maps.first) : null;
  }

  /// Search episodes by title (case-insensitive)
  Future<List<Episode>> searchByTitle(int contentId, String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'episodes',
      where: 'contentId = ? AND title LIKE ?',
      whereArgs: [contentId, '%$query%'],
      orderBy: 'seasonNumber ASC, episodeNumber ASC',
    );
    return maps.map((map) => Episode.fromMap(map)).toList();
  }

  /// Get recently added episodes for a content
  Future<List<Episode>> getRecentEpisodes(
    int contentId, {
    int limit = 5,
  }) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'episodes',
      where: 'contentId = ?',
      whereArgs: [contentId],
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return maps.map((map) => Episode.fromMap(map)).toList();
  }
}
