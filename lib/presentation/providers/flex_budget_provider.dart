import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/category.dart';
import 'category_provider.dart';
import 'transaction_provider.dart';

// --- 1. NOTIFIER UNTUK MENYIMPAN SETTING ID TRANSAKSI PEMASUKAN ---
class FlexIncomeSettingsNotifier extends Notifier<List<String>> {
  static const _key = 'flex_income_trx_ids'; // Key baru untuk Transaksi ID

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

  Future<void> toggleSource(String transactionId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = List<String>.from(state);

    if (currentList.contains(transactionId)) {
      currentList.remove(transactionId);
    } else {
      currentList.add(transactionId);
    }

    await prefs.setStringList(_key, currentList);
    state = currentList;
  }

  // Helper untuk set initial/bulk (misal Select All)
  Future<void> setAll(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids);
    state = ids;
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

  final selectedTrxIds = ref.watch(flexIncomeSettingsProvider);
  final now = DateTime.now();

  // --- A. KUMPULKAN DAN PISAHKAN SUMBER INCOME ---
  int totalUncheckedIncome = 0;
  int totalCheckedIncome = 0;

  for (var t in allTransactions) {
    if (t.type != 'income') continue;

    DateTime tDate;
    try {
      tDate = t.date;
    } catch (_) {
      tDate = DateTime.parse(t.date.toString());
    }

    final isMonthMatch = tDate.month == now.month && tDate.year == now.year;
    if (!isMonthMatch) continue;

    // CEK BERDASARKAN ID TRANSAKSI
    // Jika ID Transaksi ada di list selected, maka masuk Checked
    // ATAU jika kategori mengandung 'gaji'/'salary', anggap otomatis checked.

    final category = allCategories.firstWhere(
      (c) => c.id == t.categoryId,
      orElse: () =>
          const Category(id: 0, name: '', icon: '', color: 0, type: ''),
    );
    final isGaji =
        category.name.toLowerCase().contains('gaji') ||
        category.name.toLowerCase().contains('salary');

    if (isGaji || selectedTrxIds.contains(t.id.toString())) {
      totalCheckedIncome += t.amount;
    } else {
      totalUncheckedIncome += t.amount;
    }
  }

  // --- B. HITUNG TOTAL FIXED BUDGET ---
  int remainingFixedBudget = 0;
  for (var c in allCategories) {
    if (c.type == 'expense' && c.budget > 0) {
      remainingFixedBudget += c.budget;
    }
  }

  // --- C. ALOKASI PEMBAYARAN TAGIHAN (PERBAIKAN) ---
  // HAPUS atau KOMENTARI logika lama yang menggunakan totalUncheckedIncome
  /* LOGIKA LAMA (YANG BIKIN ERROR):
  // 1. Bayar pakai Unchecked Income dulu
  if (totalUncheckedIncome >= remainingFixedBudget) {
    remainingFixedBudget = 0;
  } else {
    remainingFixedBudget -= totalUncheckedIncome;
  }
  */

  // LOGIKA BARU:
  // Abaikan totalUncheckedIncome sepenuhnya.
  // Flex Limit murni = Total Checked Income - Total Fixed Budget.

  int flexLimit = 0;

  if (totalCheckedIncome > remainingFixedBudget) {
    // Jika pendapatan yang dicentang lebih besar dari tagihan rutin,
    // sisanya adalah Flex Budget.
    flexLimit = totalCheckedIncome - remainingFixedBudget;
  } else {
    // Jika pendapatan yang dicentang bahkan tidak cukup bayar tagihan,
    // maka Flex Budget 0 (Minus tidak ditampilkan di limit, tapi di sisa nanti).
    flexLimit = 0;
  }

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
