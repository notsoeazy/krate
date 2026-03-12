import 'package:sqflite/sqflite.dart';
import 'package:krate/data/database/app_database.dart';
import 'package:krate/data/models/episode.dart';
import 'package:krate/data/models/subtitle.dart';
import 'package:krate/utils/constants.dart';

class EpisodeRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<int> insert(Episode ep) async {
    final db = await _db.database;
    final id = await db.insert('episodes', {
      ...ep.toMap(),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    if (id > 0) {
      for (final sub in ep.subtitles) {
        await insertSubtitle(sub.copyWith(episodeId: id));
      }
    }
    return id;
  }

  Future<int> upsert(Episode ep) async {
    final db = await _db.database;
    Episode? existing;
    if (ep.id != null) {
      existing = await getById(ep.id!);
    } else {
      if (ep.seasonNumber == null) {
        // Movie episode
        existing = await getMovieEpisode(ep.contentId);
      } else {
        // Series episode
        existing = await getSeriesEpisode(
          ep.contentId,
          ep.seasonNumber!,
          ep.episodeNumber!,
        );
      }
    }

    if (existing != null) {
      final id = existing.id!;
      await db.update(
        'episodes',
        {...ep.toMap(), 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
      // Sync subtitles
      await deleteSubtitlesByEpisodeId(id);
      for (final sub in ep.subtitles) {
        await insertSubtitle(sub.copyWith(episodeId: id));
      }
      return id;
    } else {
      return await insert(ep);
    }
  }

  Future<int> update(Episode ep) async {
    if (ep.id == null) throw ArgumentError('episode.id required');
    final db = await _db.database;
    final result = await db.update(
      'episodes',
      {...ep.toMap(), 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [ep.id],
    );

    // Sync subtitles
    await deleteSubtitlesByEpisodeId(ep.id!);
    for (final sub in ep.subtitles) {
      await insertSubtitle(sub.copyWith(episodeId: ep.id!));
    }

    return result;
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    // Subtitles will be deleted by ON DELETE CASCADE
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
    if (rows.isEmpty) return null;
    final subtitles = await getSubtitlesByEpisodeId(id);
    return Episode.fromMap(rows.first, subtitles: subtitles);
  }

  Future<List<Episode>> getByContentId(int contentId) async {
    final db = await _db.database;
    final rows = await db.query(
      'episodes',
      where: 'contentId = ?',
      whereArgs: [contentId],
      orderBy: 'seasonNumber ASC, episodeNumber ASC',
    );
    
    final episodes = <Episode>[];
    for (final row in rows) {
      final subtitles = await getSubtitlesByEpisodeId(row['id'] as int);
      episodes.add(Episode.fromMap(row, subtitles: subtitles));
    }
    return episodes;
  }

  // Get the single movie episode row (seasonNumber IS NULL).
  Future<Episode?> getMovieEpisode(int contentId) async {
    final db = await _db.database;
    final rows = await db.query(
      'episodes',
      where: 'contentId = ? AND seasonNumber IS NULL',
      whereArgs: [contentId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final id = rows.first['id'] as int;
    final subtitles = await getSubtitlesByEpisodeId(id);
    return Episode.fromMap(rows.first, subtitles: subtitles);
  }

  // Get a specific series episode by season + episode number.
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
    if (rows.isEmpty) return null;
    final id = rows.first['id'] as int;
    final subtitles = await getSubtitlesByEpisodeId(id);
    return Episode.fromMap(rows.first, subtitles: subtitles);
  }

  // Returns episodes grouped by season number.
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

  // Returns the next unwatched episode after [currentEpisode] for series navigation.
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
    
    if (rows.isNotEmpty) {
      final id = rows.first['id'] as int;
      final subtitles = await getSubtitlesByEpisodeId(id);
      return Episode.fromMap(rows.first, subtitles: subtitles);
    }

    // Try first episode of next season
    rows = await db.query(
      'episodes',
      where: 'contentId = ? AND seasonNumber > ?',
      whereArgs: [currentEpisode.contentId, currentEpisode.seasonNumber],
      orderBy: 'seasonNumber ASC, episodeNumber ASC',
      limit: 1,
    );
    
    if (rows.isNotEmpty) {
      final id = rows.first['id'] as int;
      final subtitles = await getSubtitlesByEpisodeId(id);
      return Episode.fromMap(rows.first, subtitles: subtitles);
    }

    return null;
  }

  // Resets any episodes stuck in 'importing' status back to 'missing'.
  Future<void> resetImportingStatus() async {
    final db = await _db.database;
    await db.update(
      'episodes',
      {
        'fileStatus': FileStatus.missing.name,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'fileStatus = ?',
      whereArgs: [FileStatus.importing.name],
    );
  }

  // --- Subtitle Methods ---

  Future<List<Subtitle>> getSubtitlesByEpisodeId(int episodeId) async {
    final db = await _db.database;
    final rows = await db.query(
      'subtitles',
      where: 'episodeId = ?',
      whereArgs: [episodeId],
    );
    return rows.map(Subtitle.fromMap).toList();
  }

  Future<int> insertSubtitle(Subtitle sub) async {
    final db = await _db.database;
    return await db.insert('subtitles', sub.toMap());
  }

  Future<int> deleteSubtitlesByEpisodeId(int episodeId) async {
    final db = await _db.database;
    return await db.delete(
      'subtitles',
      where: 'episodeId = ?',
      whereArgs: [episodeId],
    );
  }
}
