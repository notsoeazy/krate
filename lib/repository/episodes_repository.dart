import '../database/database_helper.dart';
import '../models/app/episode_local.dart';
import 'package:sqflite/sqflite.dart';

class EpisodesRepository {
  final dbHelper = DatabaseHelper();

  /// Insert or update episode (handles UNIQUE constraint)
  Future<int> insertEpisode(Episode episode) async {
    final db = await dbHelper.database;
    return await db.insert(
      'episodes',
      episode.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update existing episode by local id
  Future<int> updateEpisode(Episode episode) async {
    if (episode.id == null) {
      throw ArgumentError('Cannot update episode without local id');
    }
    final db = await dbHelper.database;
    return await db.update(
      'episodes',
      episode.toMap(),
      where: 'id = ?',
      whereArgs: [episode.id],
    );
  }

  /// Delete episode by local id
  Future<int> deleteEpisode(int id) async {
    final db = await dbHelper.database;
    return await db.delete('episodes', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all episodes for a content, ordered by season & episode
  Future<List<Episode>> getEpisodesByContentId(int contentId) async {
    final db = await dbHelper.database;
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
    final db = await dbHelper.database;
    final maps = await db.query(
      'episodes',
      where: 'contentId = ? AND seasonNumber = ?',
      whereArgs: [contentId, seasonNumber],
      orderBy: 'episodeNumber ASC',
    );
    return maps.map((map) => Episode.fromMap(map)).toList();
  }

  /// Get single episode by local id
  Future<Episode?> getById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'episodes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) return Episode.fromMap(maps.first);
    return null;
  }

  /// Get single episode by contentId + seasonNumber + episodeNumber
  Future<Episode?> getEpisode(
    int contentId,
    int seasonNumber,
    int episodeNumber,
  ) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'episodes',
      where: 'contentId = ? AND seasonNumber = ? AND episodeNumber = ?',
      whereArgs: [contentId, seasonNumber, episodeNumber],
      limit: 1,
    );
    if (maps.isNotEmpty) return Episode.fromMap(maps.first);
    return null;
  }
}
