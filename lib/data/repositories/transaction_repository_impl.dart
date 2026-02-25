import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/local/database_helper.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final DatabaseHelper databaseHelper;

  TransactionRepositoryImpl(this.databaseHelper);

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions() async {
    try {
      final db = await databaseHelper.database;
      final result = await db.rawQuery('''
        SELECT t.id, t.title, t.amount, t.date, t.type, t.category_id,
               c.name as category_name, c.icon as category_icon, c.color as category_color, c.type as category_type
        FROM transactions t
        LEFT JOIN categories c ON t.category_id = c.id
        ORDER BY t.date DESC, t.id DESC  
      ''');

      final List<Transaction> transactions = result.map((e) {
        return TransactionModel.fromMap(e).toEntity();
      }).toList();

      return Right(transactions);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> addTransaction(Transaction transaction) async {
    try {
      final db = await databaseHelper.database;
      final transactionModel = TransactionModel(
        title: transaction.title,
        amount: transaction.amount,
        type: transaction.type,
        categoryId: transaction.categoryId,
        date: transaction.date,
        note: transaction.note,
      );

      final id = await db.insert('transactions', transactionModel.toJson());
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> updateTransaction(
    Transaction transaction,
  ) async {
    try {
      final db = await databaseHelper.database;
      final transactionModel = TransactionModel(
        id: transaction.id,
        title: transaction.title,
        amount: transaction.amount,
        type: transaction.type,
        categoryId: transaction.categoryId,
        date: transaction.date,
        note: transaction.note,
      );

      final rows = await db.update(
        'transactions',
        transactionModel.toJson(),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
      return Right(rows);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> deleteTransaction(int id) async {
    try {
      final db = await databaseHelper.database;
      final rows = await db.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
      return Right(rows);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getDashboardSummary() async {
    try {
      final db = await databaseHelper.database;

      // 1. Hitung Total Pemasukan
      final incomeResult = await db.rawQuery(
        "SELECT SUM(amount) as total FROM transactions WHERE type = 'income'",
      );
      final int income = (incomeResult.first['total'] as int?) ?? 0;

      // 2. Hitung Total Pengeluaran
      final expenseResult = await db.rawQuery(
        "SELECT SUM(amount) as total FROM transactions WHERE type = 'expense'",
      );
      final int expense = (expenseResult.first['total'] as int?) ?? 0;

      // 3. Hitung Sisa Saldo
      final int totalBalance = income - expense;

      return Right({
        'income': income,
        'expense': expense,
        'total': totalBalance,
      });
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getExpenseByCategory() async {
    try {
      final db = await databaseHelper.database;

      final result = await db.rawQuery('''
        SELECT c.name, c.color, SUM(t.amount) as total 
        FROM transactions t
        JOIN categories c ON t.category_id = c.id
        WHERE t.type = 'expense'
        GROUP BY c.name, c.color
        ORDER BY total DESC  -- <--- TAMBAHAN: Urutkan dari yang terbesar
      ''');

      final Map<String, int> data = {};
      for (var row in result) {
        final key = "${row['name']}|${row['color']}";
        final value = row['total'] as int;
        data[key] = value;
      }

      return Right(data);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> searchTransactions(
    String query,
    int walletId,
  ) async {
    try {
      final db = await databaseHelper.database;

      String sql;
      List<dynamic> args;

      if (query.trim().isEmpty) {
        // Jika query kosong, ambil SEMUA transaksi milik WALLET INI saja
        sql = '''
          SELECT t.id, t.title, t.amount, t.date, t.type, t.category_id, t.note, t.wallet_id,
                 c.name as category_name, c.icon as category_icon, c.color as category_color, c.type as category_type
          FROM transactions t
          LEFT JOIN categories c ON t.category_id = c.id
          WHERE t.wallet_id = ?
          ORDER BY t.date DESC
        ''';
        args = [walletId];
      } else {
        // Jika ada query, filter WALLET INI + JUDUL mengandung query
        sql = '''
          SELECT t.id, t.title, t.amount, t.date, t.type, t.category_id, t.note, t.wallet_id,
                 c.name as category_name, c.icon as category_icon, c.color as category_color, c.type as category_type
          FROM transactions t
          LEFT JOIN categories c ON t.category_id = c.id
          WHERE t.wallet_id = ? AND t.title LIKE ? 
          ORDER BY t.date DESC
        ''';
        args = [walletId, '%$query%'];
      }

      final result = await db.rawQuery(sql, args);

      final List<Transaction> transactions = result.map((e) {
        return TransactionModel.fromMap(e).toEntity();
      }).toList();

      return Right(transactions);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
