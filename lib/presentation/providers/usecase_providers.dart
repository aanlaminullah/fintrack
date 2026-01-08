import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- IMPORT LAMA ---
import '../../domain/usecases/add_transaction.dart';
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/get_dashboard_summary.dart';
import '../../domain/usecases/get_transactions.dart';

import '../../domain/usecases/delete_transaction.dart';
import '../../domain/usecases/update_transaction.dart';
import '../../domain/usecases/search_transactions.dart';

import '../../domain/usecases/get_expense_by_category.dart';

import '../../domain/usecases/add_category.dart';
import '../../domain/usecases/update_category.dart';
import '../../domain/usecases/delete_category.dart';

import 'repository_providers.dart';

// --- Transaction Use Cases ---

final getTransactionsProvider = Provider<GetTransactions>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return GetTransactions(repository);
});

final addTransactionProvider = Provider<AddTransaction>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return AddTransaction(repository);
});

final getDashboardSummaryProvider = Provider<GetDashboardSummary>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return GetDashboardSummary(repository);
});

// Provider baru untuk Delete
final deleteTransactionProvider = Provider<DeleteTransaction>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return DeleteTransaction(repository);
});

// Provider baru untuk Update
final updateTransactionProvider = Provider<UpdateTransaction>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return UpdateTransaction(repository);
});

// --- Category Use Cases ---

final getCategoriesProvider = Provider<GetCategories>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return GetCategories(repository);
});

final getExpenseByCategoryProvider = Provider<GetExpenseByCategory>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return GetExpenseByCategory(repository);
});

// Provider Add Category
final addCategoryProvider = Provider<AddCategory>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return AddCategory(repository);
});

// Provider Update Category
final updateCategoryProvider = Provider<UpdateCategory>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return UpdateCategory(repository);
});

// Provider Delete Category
final deleteCategoryProvider = Provider<DeleteCategory>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return DeleteCategory(repository);
});

// Provider Search Transaction
final searchTransactionsProvider = Provider<SearchTransactions>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return SearchTransactions(repository);
});
