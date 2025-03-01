
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'nids.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create rules table
    await db.execute('''
      CREATE TABLE rules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        pattern TEXT,
        severity INTEGER
      )
    ''');

    // Create logs table
    await db.execute('''
      CREATE TABLE logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        source_ip TEXT,
        destination_ip TEXT,
        protocol TEXT,
        payload TEXT
      )
    ''');
  }

  // Insert a rule
  Future<int> insertRule(Map<String, dynamic> rule) async {
    Database db = await database;
    return await db.insert('rules', rule);
  }

  // Insert a log
  Future<int> insertLog(Map<String, dynamic> log) async {
    Database db = await database;
    return await db.insert('logs', log);
  }

  // Get all rules
  Future<List<Map<String, dynamic>>> getRules() async {
    Database db = await database;
    return await db.query('rules');
  }

  // Get all logs
  Future<List<Map<String, dynamic>>> getLogs() async {
    Database db = await database;
    return await db.query('logs');
  }

  // Delete a rule
  Future<int> deleteRule(int id) async {
    Database db = await database;
    return await db.delete('rules', where: 'id = ?', whereArgs: [id]);
  }

  // Delete a log
  Future<int> deleteLog(int id) async {
    Database db = await database;
    return await db.delete('logs', where: 'id = ?', whereArgs: [id]);
  }
}
