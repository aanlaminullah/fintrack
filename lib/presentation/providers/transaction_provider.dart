import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction.dart';
import 'usecase_providers.dart';

// --- 1. Provider untuk Dashboard Summary ---
final dashboardSummaryProvider =
    AsyncNotifierProvider<DashboardSummaryNotifier, Map<String, int>>(() {
      return DashboardSummaryNotifier();
    });

class DashboardSummaryNotifier extends AsyncNotifier<Map<String, int>> {
  @override
  Future<Map<String, int>> build() async {
    // Ambil usecase
    final getDashboardSummary = ref.watch(getDashboardSummaryProvider);

    // Eksekusi logic
    final result = await getDashboardSummary();

    // Fold: Kiri (Error) -> Lempar error, Kanan (Sukses) -> Kembalikan data
    return result.fold((failure) => throw failure.message, (data) => data);
  }
}

// --- 2. Provider untuk List Transaksi (Sekaligus Controller Add/Delete) ---
final transactionListProvider =
    AsyncNotifierProvider<TransactionListNotifier, List<Transaction>>(() {
      return TransactionListNotifier();
    });

class TransactionListNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final getTransactions = ref.watch(getTransactionsProvider);
    final result = await getTransactions();

    return result.fold((failure) => throw failure.message, (data) => data);
  }

  // Fungsi Tambah Transaksi
  Future<void> addTransaction(Transaction transaction) async {
    // Set state jadi loading (opsional, agar UI disable tombol)
    state = const AsyncValue.loading();

    final addTransaction = ref.read(addTransactionProvider);
    final result = await addTransaction(transaction);

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (success) {
        ref.invalidateSelf(); // Ini akan otomatis memicu update pada Chart
        ref.invalidate(
          dashboardSummaryProvider,
        ); // Ini tetap perlu karena ambil dari DB
      },
    );
  }

  // TAMBAHAN: Fungsi Update
  Future<void> updateTransaction(Transaction transaction) async {
    state = const AsyncValue.loading();

    final updateUsecase = ref.read(updateTransactionProvider);
    final result = await updateUsecase(transaction);

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (success) {
        ref.invalidateSelf(); // Ini akan otomatis memicu update pada Chart
        ref.invalidate(
          dashboardSummaryProvider,
        ); // Ini tetap perlu karena ambil dari DB
      },
    );
  }

  // TAMBAHAN: Fungsi Delete
  Future<void> deleteTransaction(int id) async {
    // Kita tidak perlu set loading penuh agar UI tidak kedip (optimistic update optional)
    // Tapi cara paling aman:
    final deleteUsecase = ref.read(deleteTransactionProvider);
    final result = await deleteUsecase(id);

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (success) {
        ref.invalidateSelf(); // Ini akan otomatis memicu update pada Chart
        ref.invalidate(
          dashboardSummaryProvider,
        ); // Ini tetap perlu karena ambil dari DB
      },
    );
  }
}
