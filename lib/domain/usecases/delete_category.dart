import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../repositories/category_repository.dart';

class DeleteCategory {
  final CategoryRepository repository;

  DeleteCategory(this.repository);

  Future<Either<Failure, int>> call(int id) {
    return repository.deleteCategory(id);
  }
}
