import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class AddTransaction {
  final TransactionRepository repository;

  AddTransaction(this.repository);

  Future<Either<Failure, int>> call(Transaction transaction) {
    // Di sini tempat yang tepat jika Anda ingin menambah validasi bisnis
    // Contoh: Cek apakah pengeluaran > saldo (kalau logic itu ada)
    return repository.addTransaction(transaction);
  }
}
