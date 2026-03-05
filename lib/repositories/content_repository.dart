import 'package:sqflite/sqflite.dart';

import 'package:krate/constants.dart';
import 'package:krate/database/database_helper.dart';
import 'package:krate/models/app/content.dart';

class ContentRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Insert new content or update if TMDB ID already exists
  Future<int> insertContent(Content content) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'content',
      content.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update content by local ID
  Future<int> updateContent(Content content) async {
    if (content.id == null) {
      throw ArgumentError('Cannot update content without local ID');
    }
    final db = await _dbHelper.database;
    return await db.update(
      'content',
      {...content.toMap(), 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [content.id],
    );
  }

  /// Delete content by ID
  Future<int> deleteContent(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('content', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all content, optionally filtered by ContentType
  Future<List<Content>> getAllContent({ContentType? type}) async {
    final db = await _dbHelper.database;
    final maps = type != null
        ? await db.query(
            'content',
            where: 'contentType = ?',
            whereArgs: [type.name],
            orderBy: 'createdAt DESC',
          )
        : await db.query('content', orderBy: 'createdAt DESC');

    return maps.map((map) => Content.fromMap(map)).toList();
  }

  /// Get content by TMDB ID
  Future<Content?> getContentByTmdbId(int tmdbId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'content',
      where: 'tmdbId = ?',
      whereArgs: [tmdbId],
      limit: 1,
    );
    return maps.isNotEmpty ? Content.fromMap(maps.first) : null;
  }

  /// Get content by local ID
  Future<Content?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'content',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? Content.fromMap(maps.first) : null;
  }

  /// Get favorite content
  Future<List<Content>> getFavorites() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'content',
      where: 'isFavorite = 1',
      orderBy: 'updatedAt DESC',
    );
    return maps.map((map) => Content.fromMap(map)).toList();
  }

  /// Toggle favorite status
  Future<int> toggleFavorite(int contentId, bool favorite) async {
    final db = await _dbHelper.database;
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

  /// Search content by title (case-insensitive)
  Future<List<Content>> searchByTitle(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'content',
      where: 'title LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Content.fromMap(map)).toList();
  }

  /// Get recently added content
  Future<List<Content>> getRecentlyAdded({int limit = 10}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'content',
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return maps.map((map) => Content.fromMap(map)).toList();
  }
}
