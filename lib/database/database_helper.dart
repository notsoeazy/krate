import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');

    final db = await openDatabase(path, version: 1, onCreate: _onCreate);

    await db.execute('PRAGMA foreign_keys = ON');

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Content table
    // One row per movie/series/anime imported from TMDB.
    // Movies also get a single row in the episodes table (seasonNumber = NULL).
    await db.execute('''
      CREATE TABLE content(
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        tmdbId           INTEGER NOT NULL UNIQUE,
        contentType      TEXT    NOT NULL,        -- 'movie' | 'series' | 'anime'
        title            TEXT    NOT NULL,
        originalTitle    TEXT,                    -- useful for anime / foreign titles
        originalLanguage TEXT,                    -- ISO 639-1, e.g. 'ja', 'ko', 'en'
        tagline          TEXT,                    -- short TMDB tagline for detail screen
        description      TEXT,
        genres           TEXT,                    -- JSON array: '["Action","Drama"]'
        releaseDate      TEXT,                    -- ISO date: '2008-01-20'
        runtime          INTEGER,                 -- minutes; movie = film length, series = avg ep runtime
        totalSeasons     INTEGER DEFAULT 0,
        totalEpisodes    INTEGER DEFAULT 0,
        voteAverage      REAL    DEFAULT 0,       -- TMDB score 0.0–10.0
        voteCount        INTEGER DEFAULT 0,
        status           TEXT,                    -- 'Released' | 'Ended' | 'Returning Series' etc.
        posterPath       TEXT,                    -- TMDB relative path (/abc.jpg)
        backdropPath     TEXT,                    -- TMDB relative path
        localPosterPath  TEXT,                    -- absolute local file path
        localBackdropPath TEXT,                   -- absolute local file path
        isFavorite       INTEGER DEFAULT 0,
        hasFile          INTEGER DEFAULT 0,       -- 1 if movie file exists
        createdAt        TEXT    NOT NULL DEFAULT (datetime('now')),
        updatedAt        TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Episodes table
    // One row per video file. Movies have exactly one row with seasonNumber = NULL.
    // Series/anime have one row per episode.
    await db.execute('''
      CREATE TABLE episodes(
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        contentId       INTEGER NOT NULL,
        seasonNumber    INTEGER,                  -- NULL for movies
        episodeNumber   INTEGER,                  -- NULL for movies
        title           TEXT,
        description     TEXT,
        runtime         INTEGER,                  -- minutes (TMDB per-episode runtime)
        airDate         TEXT,                     -- ISO date
        videoPath       TEXT,                     -- absolute local path to video file
        subtitlePath    TEXT,                     -- path to external .srt / .ass file
        subtitleDelay   INTEGER DEFAULT 0,        -- ms offset; file-specific, saved per episode
        status          TEXT    DEFAULT 'pending', -- 'pending' | 'available' | 'missing'
        hasFile         INTEGER DEFAULT 0,        -- 1 if media file exists
        createdAt       TEXT    NOT NULL DEFAULT (datetime('now')),
        updatedAt       TEXT    NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY(contentId) REFERENCES content(id) ON DELETE CASCADE,
        UNIQUE(contentId, seasonNumber, episodeNumber)
      )
    ''');

    // WatchProgress table
    // Always keyed on episodeId — movies have one episode row so this works uniformly.
    // positionMs uses milliseconds to match media_kit's position API directly.
    await db.execute('''
      CREATE TABLE watch_progress(
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        contentId     INTEGER NOT NULL,
        episodeId     INTEGER NOT NULL,           -- always set; movies use their single episode row
        positionMs    INTEGER DEFAULT 0,          -- last playback position in milliseconds
        isFinished    INTEGER DEFAULT 0,          -- 1 when completion threshold is reached
        lastWatchedAt TEXT    NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY(contentId) REFERENCES content(id) ON DELETE CASCADE,
        FOREIGN KEY(episodeId) REFERENCES episodes(id) ON DELETE CASCADE,
        UNIQUE(episodeId)                         -- one progress row per video file
      )
    ''');
  }
}
