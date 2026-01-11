import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction.dart';
import 'transaction_provider.dart';

// 1. Ganti StateProvider dengan NotifierProvider (Lebih stabil)
class AnalysisDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void setDate(DateTime date) {
    state = date;
  }
}

final analysisDateProvider = NotifierProvider<AnalysisDateNotifier, DateTime>(
  AnalysisDateNotifier.new,
);

// --- HELPER LOGIC (Privat) ---
Map<String, int> _processChartData(
  List<Transaction> transactions,
  DateTime date,
) {
  final data = <String, int>{};

  for (var t in transactions) {
    // Filter: Harus Tipe 'expense' DAN Bulan/Tahun sama dengan yang diminta
    if (t.type == 'expense' &&
        t.date.year == date.year &&
        t.date.month == date.month) {
      // Key untuk grouping: "NamaKategori|Warna"
      final key =
          "${t.category?.name ?? 'Lainnya'}|${t.category?.color ?? 0xFF9E9E9E}";
      data[key] = (data[key] ?? 0) + t.amount;
    }
  }

  // --- LOGIC SORTING (Terbesar ke Terkecil) ---
  // 1. Ubah Map jadi List of Entries
  var sortedEntries = data.entries.toList();

  // 2. Urutkan berdasarkan value (Amount) secara Descending
  sortedEntries.sort((a, b) => b.value.compareTo(a.value));

  // 3. Kembalikan sebagai Map baru yang sudah urut
  return Map.fromEntries(sortedEntries);
}

// 2. Provider Chart Analisis (Mengikuti Bulan yang dipilih User)
final monthlyChartProvider = Provider.autoDispose<AsyncValue<Map<String, int>>>(
  (ref) {
    final selectedDate = ref.watch(analysisDateProvider);
    final transactionsState = ref.watch(transactionListProvider);

    return transactionsState.whenData((transactions) {
      return _processChartData(transactions, selectedDate);
    });
  },
);

// 3. Provider Chart Dashboard (Selalu Bulan Ini)
final dashboardChartProvider =
    Provider.autoDispose<AsyncValue<Map<String, int>>>((ref) {
      final now = DateTime.now();
      final transactionsState = ref.watch(transactionListProvider);

      return transactionsState.whenData((transactions) {
        return _processChartData(transactions, now);
      });
    });

// 4. Provider List Bulan yang Tersedia (Untuk Tab Pilihan Bulan)
final availableMonthsAnalysisProvider =
    Provider.autoDispose<AsyncValue<List<DateTime>>>((ref) {
      final transactionsState = ref.watch(transactionListProvider);

      return transactionsState.whenData((transactions) {
        final Set<String> uniqueKeys = {};
        final List<DateTime> months = [];

        for (var t in transactions) {
          final key = "${t.date.year}-${t.date.month}";
          if (!uniqueKeys.contains(key)) {
            uniqueKeys.add(key);
            months.add(DateTime(t.date.year, t.date.month, 1));
          }
        }
        months.sort((a, b) => a.compareTo(b));
        return months;
      });
    });
