import 'package:nidswebapp/wireshark/packet_data.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class SQLiteHandler {
  static final SQLiteHandler _instance = SQLiteHandler._internal();
  Map<String, Database> _databases = {};
  String _currentDbName = 'packets.db';

  factory SQLiteHandler() {
    return _instance;
  }

  SQLiteHandler._internal();

  /// Get the currently active database name
  String get currentDatabaseName => _currentDbName;

  /// Set which database file to use
  Future<void> setDatabaseFile(String dbName) async {
    // Ensure the filename ends with .db
    if (!dbName.endsWith('.db')) {
      dbName = '$dbName.db';
    }

    _currentDbName = dbName;

    // Initialize the database if it's not already open
    if (!_databases.containsKey(_currentDbName)) {
      await _initDatabase(_currentDbName);
    }

    print('Switched to database: $_currentDbName');
  }

  // /// Initialize a database with the given name
  // Future<void> _initDatabase(String dbName) async {
  //   // Initialize the web-compatible database factory
  //   var factory = databaseFactoryFfiWeb;

  //   // Open the database using the web factory
  //   Database db = await factory.openDatabase(
  //     dbName,
  //     options: OpenDatabaseOptions(
  //       version: 1,
  //       onCreate: (db, version) async {
  //         await db.execute('''
  //           CREATE TABLE packets (
  //             id INTEGER PRIMARY KEY AUTOINCREMENT,
  //             no INTEGER,
  //             time TEXT,
  //             source TEXT,
  //             destination TEXT,
  //             protocol TEXT,
  //             length INTEGER,
  //             info TEXT,
  //             type TEXT,
  //             rawData TEXT
  //           )
  //         ''');
  //       },
  //     ),
  //   );

  //   _databases[dbName] = db;
  //   print('Database $dbName initialized on Web');
  // }
  Future<void> _initDatabase(String dbName) async {
    var factory = databaseFactoryFfiWeb;

    Database db = await factory.openDatabase(
      dbName,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          // Create packets table
          await db.execute('''
          CREATE TABLE packets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            no INTEGER,
            time TEXT,
            source TEXT,
            destination TEXT,
            protocol TEXT,
            length INTEGER,
            info TEXT,
            type TEXT,
            rawData TEXT
          )
        ''');

          // Create alerts table
          await db.execute('''
          CREATE TABLE alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sid TEXT,
            msg TEXT,
            source_ip TEXT,
            source_port TEXT,
            destination_ip TEXT,
            destination_port TEXT,
            protocol TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        },
      ),
    );

    _databases[dbName] = db;
    print('Database $dbName initialized on Web');
  }

  /// Initialize the default database
  Future<void> init() async {
    await setDatabaseFile(_currentDbName);
  }

  /// Save a packet to the current database
  Future<void> savePacket(PacketData packet) async {
    // Make sure the current database is initialized
    if (!_databases.containsKey(_currentDbName)) {
      await _initDatabase(_currentDbName);
    }

    await _databases[_currentDbName]!.insert(
      'packets',
      packet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print('Packet saved to $_currentDbName');
  }

  /// Get all packets from the current database
  Future<List<PacketData>> getAllPackets() async {
    // Make sure the current database is initialized
    if (!_databases.containsKey(_currentDbName)) {
      await _initDatabase(_currentDbName);
    }

    final List<Map<String, dynamic>> maps =
        await _databases[_currentDbName]!.query('packets');

    return List.generate(maps.length, (i) {
      return PacketData.fromMap(maps[i]);
    });
  }

  /// Clear all packets from the current database
  Future<void> clearPackets() async {
    // Make sure the current database is initialized
    if (!_databases.containsKey(_currentDbName)) {
      await _initDatabase(_currentDbName);
    }

    await _databases[_currentDbName]!.delete('packets');
    print('All packets deleted from $_currentDbName');
  }

  /// List all available database files
  Future<List<String>> listDatabases() async {
    // This is a placeholder - in a real web app, you would need to use
    // browser storage APIs to list files. This method returns the databases
    // that have been opened in the current session.
    return _databases.keys.toList();
  }

  /// Close a specific database
  Future<void> closeDatabase(String dbName) async {
    if (_databases.containsKey(dbName)) {
      await _databases[dbName]!.close();
      _databases.remove(dbName);
      print('Database $dbName closed');
    }
  }

  /// Close all databases
  Future<void> closeAllDatabases() async {
    for (var db in _databases.values) {
      await db.close();
    }
    _databases.clear();
    print('All databases closed');
  }

  /// Save an alert to the current database
  Future<void> saveAlert(Map<String, dynamic> alert) async {
    if (!_databases.containsKey(_currentDbName)) {
      await _initDatabase(_currentDbName);
    }

    await _databases[_currentDbName]!.insert(
      'alerts',
      alert,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print('Alert saved to $_currentDbName');
  }

  /// Get all alerts from the current database
  Future<List<Map<String, dynamic>>> getAllAlerts() async {
    if (!_databases.containsKey(_currentDbName)) {
      await _initDatabase(_currentDbName);
    }

    return await _databases[_currentDbName]!
        .query('alerts', orderBy: 'timestamp DESC');
  }

  /// Clear all alerts from the current database
  Future<void> clearAlerts() async {
    if (!_databases.containsKey(_currentDbName)) {
      await _initDatabase(_currentDbName);
    }

    await _databases[_currentDbName]!.delete('alerts');
    print('All alerts deleted from $_currentDbName');
  }
}
