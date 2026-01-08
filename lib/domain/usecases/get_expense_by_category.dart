import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/transaction_repository.dart';

class GetExpenseByCategory {
  final TransactionRepository repository;

  GetExpenseByCategory(this.repository);

  Future<Either<Failure, Map<String, int>>> call() {
    return repository.getExpenseByCategory();
  }
}
