import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/transaction_repository.dart';

class DeleteTransaction {
  final TransactionRepository repository;

  DeleteTransaction(this.repository);

  Future<Either<Failure, int>> call(int id) {
    return repository.deleteTransaction(id);
  }
}
