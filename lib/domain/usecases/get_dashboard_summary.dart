import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/transaction_repository.dart';

class GetDashboardSummary {
  final TransactionRepository repository;

  GetDashboardSummary(this.repository);

  Future<Either<Failure, Map<String, int>>> call() {
    return repository.getDashboardSummary();
  }
}
