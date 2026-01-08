import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/local/database_helper.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final DatabaseHelper databaseHelper;

  CategoryRepositoryImpl(this.databaseHelper);

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final db = await databaseHelper.database;
      // Query raw ke tabel categories
      final result = await db.query('categories');

      // Mapping dari List<Map> ke List<Category>
      final categories = result.map((e) => CategoryModel.fromJson(e)).toList();

      return Right(categories);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> addCategory(Category category) async {
    try {
      final db = await databaseHelper.database;
      // Kita perlu cast Category entity ke CategoryModel agar bisa panggil toJson()
      final categoryModel = CategoryModel(
        name: category.name,
        icon: category.icon,
        color: category.color,
        type: category.type,
      );

      final id = await db.insert('categories', categoryModel.toJson());
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> updateCategory(Category category) async {
    try {
      final db = await databaseHelper.database;
      // Update tabel categories dimana id-nya cocok
      final result = await db.update(
        'categories',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> deleteCategory(int id) async {
    try {
      final db = await databaseHelper.database;
      final rows = await db.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );
      return Right(rows);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}
