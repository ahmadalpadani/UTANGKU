import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  bool _isInitialized = false;

  DatabaseHelper._init();

  // Initialize database explicitly
  Future<void> init() async {
    if (_isInitialized) return;
    await database;
    _isInitialized = true;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    _isInitialized = true;
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableDebts} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT,
        description TEXT,
        due_date TEXT,
        status TEXT NOT NULL,
        phone_number TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_debts_type ON ${AppConstants.tableDebts}(type)
    ''');

    await db.execute('''
      CREATE INDEX idx_debts_status ON ${AppConstants.tableDebts}(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_debts_due_date ON ${AppConstants.tableDebts}(due_date)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Future upgrades
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    _isInitialized = false;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(AppConstants.tableDebts);
  }
}
