import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('steamplanner.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        steam_id TEXT UNIQUE,
        username TEXT,
        avatar_url TEXT,
        house_id INTEGER,
        house_name TEXT,
        general_points INTEGER DEFAULT 0,
        token TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE games (
        app_id INTEGER PRIMARY KEY,
        name TEXT,
        icon_url TEXT,
        header_url TEXT,
        playtime_forever INTEGER DEFAULT 0,
        achievements_unlocked INTEGER DEFAULT 0,
        achievements_total INTEGER DEFAULT 0,
        completion_percentage REAL DEFAULT 0,
        is_complete INTEGER DEFAULT 0,
        last_synced TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        app_id INTEGER,
        api_name TEXT,
        display_name TEXT,
        description TEXT,
        icon TEXT,
        icon_gray TEXT,
        hidden INTEGER DEFAULT 0,
        unlocked INTEGER DEFAULT 0,
        unlock_time TEXT,
        global_percent REAL DEFAULT 0,
        UNIQUE(app_id, api_name)
      )
    ''');

    await db.execute('''
      CREATE TABLE medals (
        id INTEGER PRIMARY KEY,
        medal_key TEXT,
        name TEXT,
        description TEXT,
        icon TEXT,
        tier TEXT,
        points INTEGER,
        app_id INTEGER,
        game_name TEXT,
        earned_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE houses (
        id INTEGER PRIMARY KEY,
        name TEXT,
        archetype TEXT,
        color_primary TEXT,
        color_secondary TEXT,
        total_points INTEGER DEFAULT 0
      )
    ''');
  }

  // User operations
  Future<Map<String, dynamic>?> getUser() async {
    final db = await database;
    final results = await db.query('users', limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearUser() async {
    final db = await database;
    await db.delete('users');
  }

  // Games operations
  Future<List<Map<String, dynamic>>> getGames() async {
    final db = await database;
    return await db.query('games', orderBy: 'completion_percentage DESC, name ASC');
  }

  Future<void> saveGames(List<Map<String, dynamic>> games) async {
    final db = await database;
    final batch = db.batch();
    for (final game in games) {
      batch.insert('games', {
        'app_id': game['appId'],
        'name': game['name'],
        'icon_url': game['iconUrl'],
        'header_url': game['headerUrl'],
        'playtime_forever': game['playtimeForever'],
        'achievements_unlocked': game['achievementsUnlocked'],
        'achievements_total': game['achievementsTotal'],
        'completion_percentage': game['completionPercentage'],
        'is_complete': game['isComplete'] ? 1 : 0,
        'last_synced': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // Achievements operations
  Future<List<Map<String, dynamic>>> getAchievements(int appId) async {
    final db = await database;
    return await db.query('achievements', where: 'app_id = ?', whereArgs: [appId]);
  }

  Future<void> saveAchievements(int appId, List<Map<String, dynamic>> achievements) async {
    final db = await database;
    final batch = db.batch();
    for (final ach in achievements) {
      batch.insert('achievements', {
        'app_id': appId,
        'api_name': ach['apiName'],
        'display_name': ach['displayName'],
        'description': ach['description'],
        'icon': ach['icon'],
        'icon_gray': ach['iconGray'],
        'hidden': ach['hidden'] ? 1 : 0,
        'unlocked': ach['unlocked'] ? 1 : 0,
        'unlock_time': ach['unlockTime'],
        'global_percent': ach['globalPercent'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // Medals operations
  Future<List<Map<String, dynamic>>> getMedals() async {
    final db = await database;
    return await db.query('medals', orderBy: 'earned_at DESC');
  }

  Future<void> saveMedals(List<Map<String, dynamic>> medals) async {
    final db = await database;
    final batch = db.batch();
    for (final medal in medals) {
      batch.insert('medals', medal, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // Clear all data (logout)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('users');
    await db.delete('games');
    await db.delete('achievements');
    await db.delete('medals');
  }
}
