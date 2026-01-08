import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/category.dart';

abstract class CategoryRepository {
  // Get semua kategori
  Future<Either<Failure, List<Category>>> getCategories();

  // Tambah kategori
  Future<Either<Failure, int>> addCategory(Category category);

  // Edit kategori
  Future<Either<Failure, int>> updateCategory(Category category);

  // Hapus kategori
  Future<Either<Failure, int>> deleteCategory(int id);
}
