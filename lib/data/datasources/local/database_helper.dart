import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // VERSI DB 4 (Multi-Wallet)
  static const int _dbVersion = 4;

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
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migrasi Versi 2 (Budget)
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE categories ADD COLUMN budget INTEGER DEFAULT 0',
      );
    }
    // Migrasi Versi 3 (Weekly Mode)
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE categories ADD COLUMN is_weekly INTEGER DEFAULT 0',
      );
    }
    // Migrasi Versi 4 (Multi-Wallet)
    if (oldVersion < 4) {
      // 1. Buat Tabel Wallets
      await db.execute('''
        CREATE TABLE wallets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          is_monthly INTEGER DEFAULT 1
        )
      ''');

      // 2. Masukkan Wallet Default
      int defaultWalletId = await db.insert('wallets', {
        'name': 'Dompet Harian',
        'is_monthly': 1,
      });

      // 3. Tambah kolom wallet_id
      try {
        await db.execute('ALTER TABLE categories ADD COLUMN wallet_id INTEGER');
      } catch (
        _
      ) {} // Abaikan jika kolom sudah ada (kadang terjadi saat hot restart)

      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN wallet_id INTEGER',
        );
      } catch (_) {}

      // 4. Set data lama ke wallet default
      await db.execute(
        'UPDATE categories SET wallet_id = $defaultWalletId WHERE wallet_id IS NULL',
      );
      await db.execute(
        'UPDATE transactions SET wallet_id = $defaultWalletId WHERE wallet_id IS NULL',
      );
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';

    // 1. Tabel Wallets
    await db.execute('''
      CREATE TABLE wallets (
        id $idType,
        name $textType,
        is_monthly INTEGER DEFAULT 1
      )
    ''');

    // 2. Tabel Categories
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        icon $textType,
        color $intType,
        type $textType,
        budget INTEGER DEFAULT 0,
        is_weekly INTEGER DEFAULT 0,
        wallet_id INTEGER NOT NULL REFERENCES wallets(id) ON DELETE CASCADE
      )
    ''');

    // 3. Tabel Transactions
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        title $textType,
        amount $intType,
        type $textType,
        category_id $intType,
        date $textType,
        note $textNullable,
        wallet_id INTEGER NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    await _seedWalletsAndCategories(db);
  }

  Future _seedWalletsAndCategories(Database db) async {
    // 1. Buat Wallet Default
    int walletId = await db.insert('wallets', {
      'name': 'Dompet Harian',
      'is_monthly': 1,
    });

    // 2. Seed Categories
    final List<Map<String, dynamic>> defaultCategories = [
      {
        'name': 'Makan',
        'icon': 'fastfood',
        'color': 0xFFE57373,
        'type': 'expense',
        'budget': 0,
        'is_weekly': 0,
        'wallet_id': walletId,
      },
      {
        'name': 'Transport',
        'icon': 'directions_car',
        'color': 0xFF64B5F6,
        'type': 'expense',
        'budget': 0,
        'is_weekly': 0,
        'wallet_id': walletId,
      },
      {
        'name': 'Belanja',
        'icon': 'shopping_cart',
        'color': 0xFFFFD54F,
        'type': 'expense',
        'budget': 0,
        'is_weekly': 0,
        'wallet_id': walletId,
      },
      {
        'name': 'Hiburan',
        'icon': 'movie',
        'color': 0xFFBA68C8,
        'type': 'expense',
        'budget': 0,
        'is_weekly': 0,
        'wallet_id': walletId,
      },
      {
        'name': 'Gaji',
        'icon': 'attach_money',
        'color': 0xFF81C784,
        'type': 'income',
        'budget': 0,
        'is_weekly': 0,
        'wallet_id': walletId,
      },
      {
        'name': 'Freelance',
        'icon': 'computer',
        'color': 0xFF4DB6AC,
        'type': 'income',
        'budget': 0,
        'is_weekly': 0,
        'wallet_id': walletId,
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

  // --- HELPER METHODS UNTUK BACKUP & RESTORE ---

  Future<String> getDbPath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'fintrack.db');
  }

  // Menutup database agar file bisa ditimpa (Restore)
  Future<void> closeForRestore() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Alias untuk closeForRestore (dipanggil di Dashboard)
  Future<void> closeDatabase() async {
    await closeForRestore();
  }
}
