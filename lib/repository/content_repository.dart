import '../database/database_helper.dart';
import '../models/app/content.dart';
import 'package:sqflite/sqflite.dart';

class ContentRepository {
  final dbHelper = DatabaseHelper();

  /// Insert new content or update if TMDB ID already exists
  Future<int> insertContent(Content content) async {
    final db = await dbHelper.database;

    return await db.insert(
      'content',
      content.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update existing content by local id
  Future<int> updateContent(Content content) async {
    if (content.id == null) {
      throw ArgumentError('Cannot update content without local id');
    }
    final db = await dbHelper.database;
    return await db.update(
      'content',
      content.toMap(),
      where: 'id = ?',
      whereArgs: [content.id],
    );
  }

  /// Delete content by id
  Future<int> deleteContent(int id) async {
    final db = await dbHelper.database;
    return await db.delete('content', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all content, optionally filtered by type (movie/series/anime)
  Future<List<Content>> getAllContent({String? type}) async {
    final db = await dbHelper.database;
    List<Map<String, dynamic>> maps;

    if (type != null) {
      maps = await db.query(
        'content',
        where: 'contentType = ?',
        whereArgs: [type],
        orderBy: 'createdAt DESC',
      );
    } else {
      maps = await db.query('content', orderBy: 'createdAt DESC');
    }

    return maps.map((map) => Content.fromMap(map)).toList();
  }

  /// Get content by TMDB ID
  Future<Content?> getContentByTmdbId(int tmdbId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'content',
      where: 'tmdbId = ?',
      whereArgs: [tmdbId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Content.fromMap(maps.first);
    }
    return null;
  }

  /// Get content by local id
  Future<Content?> getById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'content',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Content.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Content>> getFavorites() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'content',
      where: 'isFavorite = 1',
      orderBy: 'updatedAt DESC',
    );

    return maps.map((map) => Content.fromMap(map)).toList();
  }

  Future<int> toggleFavorite(int contentId, bool favorite) async {
    final db = await dbHelper.database;
    return await db.update(
      'content',
      {
        'isFavorite': favorite ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [contentId],
    );
  }
}
