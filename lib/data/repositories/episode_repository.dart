import 'package:sqflite/sqflite.dart';
import 'package:krate/data/database/app_database.dart';
import 'package:krate/data/models/episode.dart';

class EpisodeRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<int> insert(Episode ep) async {
    final db = await _db.database;
    return db.insert('episodes', {
      ...ep.toMap(),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int> upsert(Episode ep) async {
    final db = await _db.database;
    return db.insert('episodes', {
      ...ep.toMap(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(Episode ep) async {
    if (ep.id == null) throw ArgumentError('episode.id required');
    final db = await _db.database;
    return db.update(
      'episodes',
      {...ep.toMap(), 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [ep.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete('episodes', where: 'id = ?', whereArgs: [id]);
  }

  Future<Episode?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query(
      'episodes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Episode.fromMap(rows.first);
  }

  Future<List<Episode>> getByContentId(int contentId) async {
    final db = await _db.database;
    final rows = await db.query(
      'episodes',
      where: 'contentId = ?',
      whereArgs: [contentId],
      orderBy: 'seasonNumber ASC, episodeNumber ASC',
    );
    return rows.map(Episode.fromMap).toList();
  }

  /// Get the single movie episode row (seasonNumber IS NULL).
  Future<Episode?> getMovieEpisode(int contentId) async {
    final db = await _db.database;
    final rows = await db.query(
      'episodes',
      where: 'contentId = ? AND seasonNumber IS NULL',
      whereArgs: [contentId],
      limit: 1,
    );
    return rows.isEmpty ? null : Episode.fromMap(rows.first);
  }

  /// Get a specific series episode by season + episode number.
  Future<Episode?> getSeriesEpisode(
    int contentId,
    int season,
    int episode,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'episodes',
      where: 'contentId = ? AND seasonNumber = ? AND episodeNumber = ?',
      whereArgs: [contentId, season, episode],
      limit: 1,
    );
    return rows.isEmpty ? null : Episode.fromMap(rows.first);
  }

  /// Returns episodes grouped by season number.
  Future<Map<int, List<Episode>>> getGroupedBySeasonForContent(
    int contentId,
  ) async {
    final episodes = await getByContentId(contentId);
    final grouped = <int, List<Episode>>{};
    for (final ep in episodes) {
      final s = ep.seasonNumber ?? 0;
      grouped.putIfAbsent(s, () => []).add(ep);
    }
    return grouped;
  }

  /// Returns the next unwatched episode after [currentEpisode] for series navigation.
  Future<Episode?> getNextEpisode(Episode currentEpisode) async {
    final db = await _db.database;
    // Try next episode in same season first
    var rows = await db.query(
      'episodes',
      where: 'contentId = ? AND seasonNumber = ? AND episodeNumber > ?',
      whereArgs: [
        currentEpisode.contentId,
        currentEpisode.seasonNumber,
        currentEpisode.episodeNumber,
      ],
      orderBy: 'episodeNumber ASC',
      limit: 1,
    );
    if (rows.isNotEmpty) return Episode.fromMap(rows.first);

    // Try first episode of next season
    rows = await db.query(
      'episodes',
      where: 'contentId = ? AND seasonNumber > ?',
      whereArgs: [currentEpisode.contentId, currentEpisode.seasonNumber],
      orderBy: 'seasonNumber ASC, episodeNumber ASC',
      limit: 1,
    );
    return rows.isEmpty ? null : Episode.fromMap(rows.first);
  }
}
