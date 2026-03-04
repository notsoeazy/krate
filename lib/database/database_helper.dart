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
        description TEXT NOT NULL,
        genres TEXT,
        releaseDate TEXT,
        posterPath TEXT,
        backdropPath TEXT,
        localImagePath TEXT,
        totalSeasons INTEGER,
        totalEpisodes INTEGER,
        isFavorite INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Episodes table
    await db.execute('''
      CREATE TABLE episodes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contentId INTEGER NOT NULL,
        seasonNumber INTEGER NOT NULL,
        episodeNumber INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        localVideoPath TEXT NOT NULL,
        duration INTEGER,
        airDate TEXT,
        FOREIGN KEY(contentId) REFERENCES content(id) ON DELETE CASCADE,
        UNIQUE(contentId, seasonNumber, episodeNumber)
      )
    ''');

    // WatchProgress table
    await db.execute('''
      CREATE TABLE watch_progress(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contentId INTEGER NOT NULL,
        episodeId INTEGER NOT NULL,
        progressSeconds INTEGER NOT NULL,
        isFinished INTEGER NOT NULL,
        lastWatchedAt TEXT NOT NULL,
        FOREIGN KEY(contentId) REFERENCES content(id) ON DELETE CASCADE,
        FOREIGN KEY(episodeId) REFERENCES episodes(id) ON DELETE CASCADE,
        UNIQUE(contentId, episodeId)
      )
    ''');
  }
}
