import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // VERSI DB 7 (Fix: transaksi lama tidak dipaksa punya Sumber Dana)
  static const int _dbVersion = 7;

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
      try {
        await db.execute(
          'ALTER TABLE categories ADD COLUMN budget INTEGER DEFAULT 0',
        );
      } catch (_) {}
    }
    // Migrasi Versi 3 (Weekly Mode)
    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE categories ADD COLUMN is_weekly INTEGER DEFAULT 0',
        );
      } catch (_) {}
    }
    // Migrasi Versi 4 (Multi-Wallet)
    if (oldVersion < 4) {
      // 1. Buat Tabel Wallets
      await db.execute('''
        CREATE TABLE IF NOT EXISTS wallets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          is_monthly INTEGER DEFAULT 1,
          is_active INTEGER DEFAULT 1
        )
      ''');

      // 2. Masukkan Wallet Default jika belum ada
      final existingWallets = await db.query('wallets');
      int defaultWalletId;
      if (existingWallets.isEmpty) {
        defaultWalletId = await db.insert('wallets', {
          'name': 'Dompet Harian',
          'is_monthly': 1,
          'is_active': 1,
        });
      } else {
        defaultWalletId = existingWallets.first['id'] as int;
      }

      // 3. Tambah kolom wallet_id
      try {
        await db.execute('ALTER TABLE categories ADD COLUMN wallet_id INTEGER');
      } catch (_) {}

      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN wallet_id INTEGER',
        );
      } catch (_) {}

      // 4. Set data lama ke wallet default
      try {
        await db.execute(
          'UPDATE categories SET wallet_id = $defaultWalletId WHERE wallet_id IS NULL',
        );
      } catch (_) {}
      try {
        await db.execute(
          'UPDATE transactions SET wallet_id = $defaultWalletId WHERE wallet_id IS NULL',
        );
      } catch (_) {}
    }
    // Migrasi Versi 5 (Wallet Active/Inactive)
    if (oldVersion < 5) {
      try {
        await db.execute(
          'ALTER TABLE wallets ADD COLUMN is_active INTEGER DEFAULT 1',
        );
      } catch (_) {}
    }
    // Migrasi Versi 6 (Funding Source: Tunai/Rekening + Transfer)
    if (oldVersion < 6) {
      // 1. Buat Tabel Funding Sources
      await db.execute('''
        CREATE TABLE IF NOT EXISTS funding_sources (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          initial_balance INTEGER DEFAULT 0,
          is_active INTEGER DEFAULT 1
        )
      ''');

      // 2. Buat Tabel Transfer Antar Sumber Dana
      await db.execute('''
        CREATE TABLE IF NOT EXISTS funding_source_transfers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          from_source_id INTEGER NOT NULL REFERENCES funding_sources(id) ON DELETE CASCADE,
          to_source_id INTEGER NOT NULL REFERENCES funding_sources(id) ON DELETE CASCADE,
          amount INTEGER NOT NULL,
          date TEXT NOT NULL,
          note TEXT
        )
      ''');

      // 3. Seed Funding Source Default jika belum ada
      final existingSources = await db.query('funding_sources');
      if (existingSources.isEmpty) {
        await db.insert('funding_sources', {
          'name': 'Tunai',
          'initial_balance': 0,
          'is_active': 1,
        });
      }

      // 4. Tambah kolom funding_source_id ke transactions
      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN funding_source_id INTEGER',
        );
      } catch (_) {}
    }
    // Migrasi Versi 7 (Pastikan funding_source_id dan tabel transfer ada)
    if (oldVersion < 7) {
      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN funding_source_id INTEGER',
        );
      } catch (_) {}
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';

    // 1. Tabel Wallets
    await db.execute('''
      CREATE TABLE IF NOT EXISTS wallets (
        id $idType,
        name $textType,
        is_monthly INTEGER DEFAULT 1,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // 2. Tabel Categories
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
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

    // 3. Tabel Funding Sources
    await db.execute('''
      CREATE TABLE IF NOT EXISTS funding_sources (
        id $idType,
        name $textType,
        initial_balance INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // 4. Tabel Transactions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id $idType,
        title $textType,
        amount $intType,
        type $textType,
        category_id INTEGER,
        date $textType,
        note $textNullable,
        wallet_id INTEGER NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
        funding_source_id INTEGER REFERENCES funding_sources(id),
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // 5. Tabel Transfer Antar Sumber Dana
    await db.execute('''
      CREATE TABLE IF NOT EXISTS funding_source_transfers (
        id $idType,
        from_source_id INTEGER NOT NULL REFERENCES funding_sources(id) ON DELETE CASCADE,
        to_source_id INTEGER NOT NULL REFERENCES funding_sources(id) ON DELETE CASCADE,
        amount $intType,
        date $textType,
        note $textNullable
      )
    ''');

    await _seedWalletsAndCategories(db);
    await _seedFundingSources(db);
  }

  Future _seedFundingSources(Database db) async {
    final existing = await db.query('funding_sources');
    if (existing.isEmpty) {
      await db.insert('funding_sources', {
        'name': 'Tunai',
        'initial_balance': 0,
        'is_active': 1,
      });
    }
  }

  Future _seedWalletsAndCategories(Database db) async {
    // 1. Buat Wallet Default
    int walletId = await db.insert('wallets', {
      'name': 'Dompet Harian',
      'is_monthly': 1,
      'is_active': 1,
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

  // Restore aman: menutup DB, hapus WAL/journal, salin file baru, dan buka kembali
  Future<void> restoreDatabase(File backupFile) async {
    await closeForRestore();

    final dbPath = await getDbPath();
    final walFile = File('$dbPath-wal');
    final shmFile = File('$dbPath-shm');
    final journalFile = File('$dbPath-journal');

    if (await walFile.exists()) {
      try {
        await walFile.delete();
      } catch (_) {}
    }
    if (await shmFile.exists()) {
      try {
        await shmFile.delete();
      } catch (_) {}
    }
    if (await journalFile.exists()) {
      try {
        await journalFile.delete();
      } catch (_) {}
    }

    await backupFile.copy(dbPath);

    // Buka kembali database untuk memicu migrasi & pastikan DB valid
    _database = await _initDB('fintrack.db');
  }
}
