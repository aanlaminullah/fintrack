import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/category.dart';
import 'category_provider.dart';
import 'transaction_provider.dart';

// --- 1. NOTIFIER UNTUK MENYIMPAN SETTING SUMBER PEMASUKAN ---
class FlexIncomeSettingsNotifier extends Notifier<List<String>> {
  static const _key = 'flex_income_source_ids';

  @override
  List<String> build() {
    _loadPreferences();
    return [];
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIds = prefs.getStringList(_key) ?? [];
    state = savedIds;
  }

  Future<void> toggleSource(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = List<String>.from(state);

    if (currentList.contains(categoryId)) {
      currentList.remove(categoryId);
    } else {
      currentList.add(categoryId);
    }

    await prefs.setStringList(_key, currentList);
    state = currentList;
  }
}

final flexIncomeSettingsProvider =
    NotifierProvider<FlexIncomeSettingsNotifier, List<String>>(
      FlexIncomeSettingsNotifier.new,
    );

// --- 2. MODEL DATA HASIL KALKULASI FLEX ---
class FlexBudgetState {
  final int limit; // Batas Maksimal
  final int used; // Terpakai
  final int remaining; // Sisa
  final double percentage;

  FlexBudgetState({
    required this.limit,
    required this.used,
    required this.remaining,
    required this.percentage,
  });
}

// --- 3. PROVIDER KALKULASI UTAMA (YANG DIPERBAIKI) ---
final flexBudgetCalculationProvider = Provider.autoDispose<FlexBudgetState>((
  ref,
) {
  // Ambil Data Dasar
  final allTransactions = ref.watch(transactionListProvider).value ?? [];
  final allCategoriesRaw = ref.watch(categoryListProvider).value ?? [];

  // --- PERBAIKAN DISINI: CAST KE TIPE INDUK (Category) ---
  // Agar tidak terjadi error subtype CategoryModel vs Category
  final allCategories = allCategoriesRaw.cast<Category>().toList();

  final selectedIncomeIds = ref.watch(flexIncomeSettingsProvider);

  // --- A. HITUNG PEMASUKAN YANG DIPILIH (Income Pool) ---
  final now = DateTime.now();

  // Filter Kategori Income
  final incomeCategories = allCategories
      .where((c) => c.type == 'income')
      .toList();

  // Logic Default: Cari "Gaji" atau ambil yang pertama
  List<String> effectiveIds = [];
  if (selectedIncomeIds.isEmpty) {
    Category? defaultCat;

    // Cari kategori yang namanya mengandung "gaji" atau "salary"
    try {
      defaultCat = incomeCategories.firstWhere(
        (c) =>
            c.name.toLowerCase().contains('gaji') ||
            c.name.toLowerCase().contains('salary'),
      );
    } catch (_) {
      // Jika tidak ketemu (error StateError), cek apakah list ada isinya
      if (incomeCategories.isNotEmpty) {
        defaultCat = incomeCategories.first;
      }
    }

    // Jika ketemu, jadikan default
    if (defaultCat != null && defaultCat.id != null) {
      effectiveIds = [defaultCat.id.toString()];
    }
  } else {
    effectiveIds = selectedIncomeIds;
  }

  // 2. Hitung Total Income Real
  int totalFlexIncome = allTransactions
      .where((t) {
        DateTime tDate;
        try {
          tDate = t.date;
        } catch (_) {
          tDate = DateTime.parse(t.date.toString());
        }

        final isMonthMatch = tDate.month == now.month && tDate.year == now.year;
        final isSelectedCategory = effectiveIds.contains(
          t.categoryId.toString(),
        );

        return t.type == 'income' && isMonthMatch && isSelectedCategory;
      })
      .fold(0, (sum, t) => sum + t.amount);

  // --- B. HITUNG TOTAL FIXED BUDGET ---
  int totalFixedBudget = 0;
  for (var c in allCategories) {
    if (c.type == 'expense' && c.budget > 0) {
      totalFixedBudget += c.budget;
    }
  }

  // --- C. HITUNG LIMIT FLEX ---
  int flexLimit = totalFlexIncome - totalFixedBudget;
  if (flexLimit < 0) flexLimit = 0;

  // --- D. HITUNG PENGELUARAN FLEX (Non-Budgeted Expenses) ---
  final budgetedCategoryIds = allCategories
      .where((c) => c.type == 'expense' && c.budget > 0)
      .map((c) => c.id)
      .toSet();

  int flexUsed = allTransactions
      .where((t) {
        DateTime tDate;
        try {
          tDate = t.date;
        } catch (_) {
          tDate = DateTime.parse(t.date.toString());
        }

        final isMonthMatch = tDate.month == now.month && tDate.year == now.year;
        final isExpense = t.type == 'expense';
        final isNonBudgeted = !budgetedCategoryIds.contains(t.categoryId);

        return isExpense && isMonthMatch && isNonBudgeted;
      })
      .fold(0, (sum, t) => sum + t.amount);

  // --- E. HASIL ---
  double percentage = flexLimit == 0 ? 0.0 : flexUsed / flexLimit;
  if (percentage > 1.0) percentage = 1.0;

  return FlexBudgetState(
    limit: flexLimit,
    used: flexUsed,
    remaining: flexLimit - flexUsed,
    percentage: percentage,
  );
});
