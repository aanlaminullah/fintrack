import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // VERSI NAIK JADI 3
  static const int _dbVersion = 3;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fintrack.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // <--- Handle Migrasi
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // MIGRASI DATABASE (Agar data lama tidak hilang)
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE categories ADD COLUMN budget INTEGER DEFAULT 0',
      );
    }
    // Update Versi 3: Tambah kolom is_weekly
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE categories ADD COLUMN is_weekly INTEGER DEFAULT 0',
      );
      print("Database upgraded to v3: Added is_weekly column");
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';

    // Tabel Categories (Lengkap dengan is_weekly)
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        icon $textType,
        color $intType,
        type $textType,
        budget INTEGER DEFAULT 0,
        is_weekly INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        title $textType,
        amount $intType,
        type $textType,
        category_id $intType,
        date $textType,
        note $textNullable,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    await _seedCategories(db);
  }

  Future _seedCategories(Database db) async {
    final List<Map<String, dynamic>> defaultCategories = [
      {
        'name': 'Makan',
        'icon': 'fastfood',
        'color': 0xFFE57373,
        'type': 'expense',
        'budget': 0,
        'is_weekly': 0,
      },
      {
        'name': 'Transport',
        'icon': 'directions_car',
        'color': 0xFF64B5F6,
        'type': 'expense',
        'budget': 0,
        'is_weekly': 0,
      },
      {
        'name': 'Belanja',
        'icon': 'shopping_cart',
        'color': 0xFFFFD54F,
        'type': 'expense',
        'budget': 0,
        'is_weekly': 0,
      },
      {
        'name': 'Hiburan',
        'icon': 'movie',
        'color': 0xFFBA68C8,
        'type': 'expense',
        'budget': 0,
        'is_weekly': 0,
      },
      {
        'name': 'Gaji',
        'icon': 'attach_money',
        'color': 0xFF81C784,
        'type': 'income',
        'budget': 0,
        'is_weekly': 0,
      },
      {
        'name': 'Freelance',
        'icon': 'computer',
        'color': 0xFF4DB6AC,
        'type': 'income',
        'budget': 0,
        'is_weekly': 0,
      },
    ];

    for (var cat in defaultCategories) {
      await db.insert('categories', cat);
    }
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }

  Future<String> getDbPath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'fintrack.db');
  }

  Future<void> closeForRestore() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
