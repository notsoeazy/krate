import 'package:sqflite/sqflite.dart';
import 'package:krate/core/constants.dart';
import 'package:krate/data/database/app_database.dart';
import 'package:krate/data/models/content.dart';

class ContentRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<int> insert(Content content) async {
    final db = await _db.database;
    return db.insert('content', {
      ...content.toMap(),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int> upsert(Content content) async {
    final db = await _db.database;
    return db.insert('content', {
      ...content.toMap(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(Content content) async {
    if (content.id == null) throw ArgumentError('content.id required');
    final db = await _db.database;
    return db.update(
      'content',
      {...content.toMap(), 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [content.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('content', where: 'id = ?', whereArgs: [id]);
  }

  Future<Content?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query(
      'content',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Content.fromMap(rows.first);
  }

  Future<Content?> getByTmdbId(int tmdbId) async {
    final db = await _db.database;
    final rows = await db.query(
      'content',
      where: 'tmdbId = ?',
      whereArgs: [tmdbId],
      limit: 1,
    );
    return rows.isEmpty ? null : Content.fromMap(rows.first);
  }

  Future<List<Content>> getAll({ContentType? type}) async {
    final db = await _db.database;
    final rows = type != null
        ? await db.query(
            'content',
            where: 'contentType = ?',
            whereArgs: [type.name],
            orderBy: 'createdAt DESC',
          )
        : await db.query('content', orderBy: 'createdAt DESC');
    return rows.map(Content.fromMap).toList();
  }

  Future<List<Content>> getRecentlyAdded({
    ContentType? type,
    int limit = 10,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'content',
      where: type != null ? 'contentType = ?' : null,
      whereArgs: type != null ? [type.name] : null,
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return rows.map(Content.fromMap).toList();
  }

  Future<List<Content>> search(String query) async {
    final db = await _db.database;
    final rows = await db.query(
      'content',
      where: 'title LIKE ? OR originalTitle LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'title ASC',
    );
    return rows.map(Content.fromMap).toList();
  }

  Future<List<Content>> getFavorites() async {
    final db = await _db.database;
    final rows = await db.query(
      'content',
      where: 'isFavorite = 1',
      orderBy: 'title ASC',
    );
    return rows.map(Content.fromMap).toList();
  }

  Future<void> setFavorite(int id, bool value) async {
    final db = await _db.database;
    await db.update(
      'content',
      {
        'isFavorite': value ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Returns all items where [fileStatus] is not 'ready'.
  Future<List<Content>> getGhosts() async {
    final db = await _db.database;
    final rows = await db.query(
      'content',
      where: 'fileStatus != ?',
      whereArgs: [FileStatus.ready.name],
    );
    return rows.map(Content.fromMap).toList();
  }
}
