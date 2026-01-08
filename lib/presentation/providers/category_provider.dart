import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category.dart';
import 'usecase_providers.dart';

final categoryListProvider = FutureProvider<List<Category>>((ref) async {
  final getCategories = ref.watch(getCategoriesProvider);
  final result = await getCategories();

  return result.fold((failure) => throw failure.message, (data) => data);
});
