import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'usecase_providers.dart';

// Provider ini mengembalikan Map<String, int> -> {"Makan|Color": 50000}
final expenseByCategoryProvider = FutureProvider.autoDispose<Map<String, int>>((
  ref,
) async {
  final useCase = ref.watch(getExpenseByCategoryProvider);
  final result = await useCase();

  return result.fold(
    (failure) => {}, // Kalau error kembalikan map kosong
    (data) => data,
  );
});
