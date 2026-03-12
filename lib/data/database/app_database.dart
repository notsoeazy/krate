import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'krate.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Content table stores movie and series metadata
    await db.execute('''
      CREATE TABLE content (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        tmdbId            INTEGER NOT NULL UNIQUE,
        contentType       TEXT    NOT NULL,           -- 'movie' | 'series'
        title             TEXT    NOT NULL,
        originalTitle     TEXT,
        originalLanguage  TEXT,
        tagline           TEXT,
        description       TEXT,
        genres            TEXT,                       -- JSON encoded list
        releaseDate       TEXT,                       -- ISO 8601
        runtime           INTEGER,                    -- minutes
        totalSeasons      INTEGER DEFAULT 0,
        totalEpisodes     INTEGER DEFAULT 0,
        voteAverage       REAL    DEFAULT 0,
        voteCount         INTEGER DEFAULT 0,
        tmdbStatus        TEXT,                       -- 'Released' | 'Ended' etc.
        tmdbPosterPath    TEXT,                       -- TMDB remote poster path
        tmdbBackdropPath  TEXT,                       -- TMDB remote backdrop path
        localPosterPath   TEXT,                       -- absolute local path
        localBackdropPath TEXT,                       -- absolute local path
        podPath           TEXT,                       -- absolute pod folder path
        isFavorite        INTEGER DEFAULT 0,
        fileStatus        TEXT    DEFAULT 'missing',  -- 'ready' | 'missing' | 'importing'
        createdAt         TEXT    NOT NULL DEFAULT (datetime('now')),
        updatedAt         TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Episodes table stores individual movie/series episode details
    await db.execute('''
      CREATE TABLE episodes (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        contentId       INTEGER NOT NULL,
        seasonNumber    INTEGER,                      -- NULL for movies
        episodeNumber   INTEGER,                      -- NULL for movies
        title           TEXT,
        description     TEXT,
        runtime         INTEGER,
        airDate         TEXT,
        videoPath       TEXT,
        fileStatus      TEXT    DEFAULT 'missing',
        createdAt       TEXT    NOT NULL DEFAULT (datetime('now')),
        updatedAt       TEXT    NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (contentId) REFERENCES content(id) ON DELETE CASCADE,
        UNIQUE (contentId, seasonNumber, episodeNumber)
      )
    ''');

    // Subtitles table for multiple subtitle files per episode
    await db.execute('''
      CREATE TABLE subtitles (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        episodeId INTEGER NOT NULL,
        path      TEXT    NOT NULL,
        name      TEXT    NOT NULL,
        FOREIGN KEY (episodeId) REFERENCES episodes(id) ON DELETE CASCADE
      )
    ''');

    // Watch progress tracked per episode
    await db.execute('''
      CREATE TABLE watch_progress (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        contentId      INTEGER NOT NULL,
        episodeId      INTEGER NOT NULL UNIQUE,
        positionMs     INTEGER DEFAULT 0,
        durationMs     INTEGER DEFAULT 0,
        isFinished     INTEGER DEFAULT 0,
        lastWatchedAt  TEXT    NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (contentId) REFERENCES content(id) ON DELETE CASCADE,
        FOREIGN KEY (episodeId) REFERENCES episodes(id) ON DELETE CASCADE
      )
    ''');

    // Watch history for viewing sessions
    await db.execute('''
      CREATE TABLE watch_history (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        contentId         INTEGER NOT NULL,
        episodeId         INTEGER NOT NULL,
        startedAt         TEXT    NOT NULL,
        finishedAt        TEXT    NOT NULL,
        durationWatchedMs INTEGER DEFAULT 0,
        FOREIGN KEY (contentId) REFERENCES content(id) ON DELETE CASCADE,
        FOREIGN KEY (episodeId) REFERENCES episodes(id) ON DELETE CASCADE
      )
    ''');

    // Indexes for common query patterns
    await db.execute('CREATE INDEX idx_content_type ON content(contentType)');
    await db.execute(
      'CREATE INDEX idx_episodes_content ON episodes(contentId)',
    );
    await db.execute(
      'CREATE INDEX idx_wp_content ON watch_progress(contentId)',
    );
    await db.execute(
      'CREATE INDEX idx_history_content ON watch_history(contentId)',
    );
    await db.execute(
      'CREATE INDEX idx_history_started ON watch_history(startedAt)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add subtitles table
      await db.execute('''
        CREATE TABLE subtitles (
          id        INTEGER PRIMARY KEY AUTOINCREMENT,
          episodeId INTEGER NOT NULL,
          path      TEXT    NOT NULL,
          name      TEXT    NOT NULL,
          FOREIGN KEY (episodeId) REFERENCES episodes(id) ON DELETE CASCADE
        )
      ''');
    }
  }
}
