import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class SearchTransactions {
  final TransactionRepository repository;

  SearchTransactions(this.repository);

  Future<Either<Failure, List<Transaction>>> call(String query) {
    return repository.searchTransactions(query);
  }
}
