import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class GetTransactions {
  final TransactionRepository repository;

  GetTransactions(this.repository);

  // Method call() membuat class ini bisa dipanggil seperti fungsi
  // Contoh: getTransactions() alih-alih getTransactions.execute()
  Future<Either<Failure, List<Transaction>>> call() {
    return repository.getTransactions();
  }
}
