import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Getter untuk mengambil instance database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fintrack.db');
    return _database!;
  }

  // Inisialisasi Database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      // Mengaktifkan foreign key support (penting untuk relasi kategori)
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // Membuat Tabel saat pertama kali install
  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';

    // 1. Buat Tabel Categories
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        icon $textType,
        color $intType,
        type $textType
      )
    ''');

    // 2. Buat Tabel Transactions
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

    // 3. Isi data awal kategori (Seeding)
    await _seedCategories(db);
  }

  // Data awal agar user langsung punya kategori
  Future _seedCategories(Database db) async {
    final List<Map<String, dynamic>> defaultCategories = [
      // Pengeluaran
      {
        'name': 'Makan',
        'icon': 'fastfood',
        'color': 0xFFE57373,
        'type': 'expense',
      },
      {
        'name': 'Transport',
        'icon': 'directions_car',
        'color': 0xFF64B5F6,
        'type': 'expense',
      },
      {
        'name': 'Belanja',
        'icon': 'shopping_cart',
        'color': 0xFFFFD54F,
        'type': 'expense',
      },
      {
        'name': 'Hiburan',
        'icon': 'movie',
        'color': 0xFFBA68C8,
        'type': 'expense',
      },
      // Pemasukan
      {
        'name': 'Gaji',
        'icon': 'attach_money',
        'color': 0xFF81C784,
        'type': 'income',
      },
      {
        'name': 'Freelance',
        'icon': 'computer',
        'color': 0xFF4DB6AC,
        'type': 'income',
      },
    ];

    for (var cat in defaultCategories) {
      await db.insert('categories', cat);
    }
  }

  // Method Helper untuk menutup koneksi (opsional)
  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // FITUR BACKUP: Ambil path file database saat ini
  Future<String> getDbPath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'fintrack.db');
  }

  // FITUR RESTORE: Tutup koneksi agar file bisa ditimpa
  Future<void> closeForRestore() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null; // Reset instance
    }
  }

  // FITUR RESTORE & BACKUP: Tutup koneksi agar file tersimpan sempurna
  Future<void> closeDatabase() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database =
          null; // Reset instance agar nanti dibuka ulang saat ada query baru
    }
  }
}
