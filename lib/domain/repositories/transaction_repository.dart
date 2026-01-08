import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/transaction.dart';

abstract class TransactionRepository {
  // Mengambil semua transaksi
  Future<Either<Failure, List<Transaction>>> getTransactions();

  // Menambah transaksi baru
  Future<Either<Failure, int>> addTransaction(Transaction transaction);

  // Update transaksi
  Future<Either<Failure, int>> updateTransaction(Transaction transaction);

  // Hapus transaksi
  Future<Either<Failure, int>> deleteTransaction(int id);

  // Mengambil ringkasan dashboard (Total Balance, Income, Expense)
  // Kita kembalikan Map sederhana dulu untuk kemudahan
  Future<Either<Failure, Map<String, int>>> getDashboardSummary();

  // Tambahkan ini: Mengambil total pengeluaran dikelompokkan per kategori
  Future<Either<Failure, Map<String, int>>> getExpenseByCategory();

  // TAMBAHAN: Search
  Future<Either<Failure, List<Transaction>>> searchTransactions(String query);
}
