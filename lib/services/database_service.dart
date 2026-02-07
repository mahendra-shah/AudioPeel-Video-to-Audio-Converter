import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';
import '../models/audio_file.dart';
import '../utils/logger.dart';

/// Provides CRUD operations for conversion history stored in SQLite.
///
/// Access via [DatabaseService.instance] (singleton).
class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Database? _database;

  /// Returns the open database, initialising it lazily on first access.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // ─── Initialisation ─────────────────────────────────────────────────

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, AppConstants.databaseName);

    Logger.info('Opening database at $path', 'DatabaseService');

    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE conversions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        input_video_name TEXT NOT NULL,
        input_video_path TEXT NOT NULL,
        output_audio_name TEXT NOT NULL,
        output_audio_path TEXT NOT NULL,
        quality INTEGER NOT NULL,
        file_size INTEGER NOT NULL,
        duration INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        error_message TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_created_at ON conversions(created_at DESC)',
    );
    await db.execute('CREATE INDEX idx_quality ON conversions(quality)');
    await db.execute('CREATE INDEX idx_status ON conversions(status)');

    Logger.info('Database created with v$version schema', 'DatabaseService');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    Logger.info(
      'Upgrading database from v$oldVersion to v$newVersion',
      'DatabaseService',
    );
    // Future migrations go here.
  }

  // ─── Insert ─────────────────────────────────────────────────────────

  /// Inserts a conversion record and returns its database `id`.
  Future<int> insertConversion(AudioFile audioFile) async {
    final db = await database;
    final id = await db.insert('conversions', audioFile.toMap());
    Logger.debug('Inserted conversion id=$id', 'DatabaseService');
    return id;
  }

  // ─── Read ───────────────────────────────────────────────────────────

  /// Returns all completed conversions, newest first.
  Future<List<AudioFile>> allConversions() async {
    final db = await database;
    final rows = await db.query(
      'conversions',
      where: "status = 'completed'",
      orderBy: 'created_at DESC',
    );
    return rows.map(AudioFile.fromMap).toList();
  }

  /// Returns completed conversions created today.
  Future<List<AudioFile>> todayConversions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _completedSince(startOfDay);
  }

  /// Returns completed conversions from the last 7 days.
  Future<List<AudioFile>> last7DaysConversions() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return _completedSince(sevenDaysAgo);
  }

  /// Returns only high-quality (320 kbps) completed conversions.
  Future<List<AudioFile>> highQualityConversions() async {
    final db = await database;
    final rows = await db.query(
      'conversions',
      where: "status = 'completed' AND quality = 320",
      orderBy: 'created_at DESC',
    );
    return rows.map(AudioFile.fromMap).toList();
  }

  /// Searches completed conversions by file name (input or output).
  Future<List<AudioFile>> searchConversions(String query) async {
    final db = await database;
    final pattern = '%$query%';
    final rows = await db.query(
      'conversions',
      where:
          "status = 'completed' AND "
          '(input_video_name LIKE ? OR output_audio_name LIKE ?)',
      whereArgs: [pattern, pattern],
      orderBy: 'created_at DESC',
    );
    return rows.map(AudioFile.fromMap).toList();
  }

  /// Returns the most recent [limit] completed conversions.
  Future<List<AudioFile>> recentConversions({int limit = 5}) async {
    final db = await database;
    final rows = await db.query(
      'conversions',
      where: "status = 'completed'",
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(AudioFile.fromMap).toList();
  }

  /// Returns the total count of completed conversions.
  Future<int> totalCompletedCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM conversions WHERE status = 'completed'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ─── Delete ─────────────────────────────────────────────────────────

  /// Deletes a single conversion by [id]. Returns the number of rows removed.
  Future<int> deleteConversion(int id) async {
    final db = await database;
    final count = await db.delete(
      'conversions',
      where: 'id = ?',
      whereArgs: [id],
    );
    Logger.debug('Deleted conversion id=$id (rows=$count)', 'DatabaseService');
    return count;
  }

  /// Deletes a conversion by its output audio path.
  ///
  /// Returns the number of rows removed.
  Future<int> deleteConversionByPath(String outputAudioPath) async {
    final db = await database;
    final count = await db.delete(
      'conversions',
      where: 'output_audio_path = ?',
      whereArgs: [outputAudioPath],
    );
    Logger.debug(
      'Deleted conversion path=$outputAudioPath (rows=$count)',
      'DatabaseService',
    );
    return count;
  }

  /// Clears all conversion history. Returns the number of rows removed.
  Future<int> clearAllConversions() async {
    final db = await database;
    final count = await db.delete('conversions');
    Logger.info('Cleared all conversions (rows=$count)', 'DatabaseService');
    return count;
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  Future<List<AudioFile>> _completedSince(DateTime since) async {
    final db = await database;
    final rows = await db.query(
      'conversions',
      where: "status = 'completed' AND created_at >= ?",
      whereArgs: [since.millisecondsSinceEpoch],
      orderBy: 'created_at DESC',
    );
    return rows.map(AudioFile.fromMap).toList();
  }

  /// Closes the database. Call during app teardown if needed.
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
