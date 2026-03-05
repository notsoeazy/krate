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
    await db.execute('''
      CREATE TABLE content(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tmdbId INTEGER UNIQUE,
        contentType TEXT NOT NULL,
        title TEXT NOT NULL,
        originalTitle TEXT,
        originalLanguage TEXT,
        description TEXT,
        genres TEXT,
        releaseDate TEXT,
        posterPath TEXT,
        backdropPath TEXT,
        localPosterPath TEXT,
        localBackdropPath TEXT,
        videoPath TEXT,
        duration INTEGER,
        totalSeasons INTEGER DEFAULT 0,
        totalEpisodes INTEGER DEFAULT 0,
        isFavorite INTEGER DEFAULT 0,
        status TEXT,
        createdAt TEXT NOT NULL DEFAULT (datetime('now')),
        updatedAt TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Episodes table
    await db.execute('''
      CREATE TABLE episodes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contentId INTEGER NOT NULL,
        seasonNumber INTEGER NOT NULL,
        episodeNumber INTEGER NOT NULL,
        title TEXT,
        description TEXT,
        videoPath TEXT,
        duration INTEGER DEFAULT 0,
        airDate TEXT,
        status TEXT DEFAULT 'pending',
        createdAt TEXT NOT NULL DEFAULT (datetime('now')),
        updatedAt TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY(contentId) REFERENCES content(id) ON DELETE CASCADE,
        UNIQUE(contentId, seasonNumber, episodeNumber)
      )
    ''');

    // WatchProgress table
    await db.execute('''
      CREATE TABLE watch_progress(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contentId INTEGER NOT NULL,
        episodeId INTEGER,
        progressSeconds INTEGER DEFAULT 0,
        isFinished INTEGER DEFAULT 0,
        lastWatchedAt TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY(contentId) REFERENCES content(id) ON DELETE CASCADE,
        FOREIGN KEY(episodeId) REFERENCES episodes(id) ON DELETE CASCADE,
        UNIQUE(contentId, episodeId)
      )
    ''');
  }
}
