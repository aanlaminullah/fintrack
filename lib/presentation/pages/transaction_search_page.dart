import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // Wajib import intl untuk nama bulan
import '../providers/usecase_providers.dart';
import '../providers/transaction_provider.dart';
import '../../domain/entities/transaction.dart';
import '../widgets/transaction_item.dart';
import 'add_transaction_page.dart';

// 1. Notifier untuk Search Query (Teks Pencarian)
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

// 2. Notifier untuk Selected Month (Tab Bulan yang dipilih)
class SelectedMonthNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null; // Awalnya null, nanti diisi otomatis oleh UI
  void selectMonth(DateTime date) => state = date;
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime?>(
      SelectedMonthNotifier.new,
    );

// 3. Provider Utama: Mengambil Data & Melakukan Filtering (Search + Bulan)
final filteredTransactionsProvider = FutureProvider.autoDispose<List<Transaction>>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);

  // Ambil UseCase
  final searchUseCase = ref.watch(searchTransactionsProvider);

  // Refresh jika ada perubahan database (CRUD)
  ref.watch(transactionListProvider);

  // Ambil data dari database (Query text)
  // Jika query kosong, dia akan ambil semua data (sesuai logic repo kita)
  final result = await searchUseCase(query);

  return result.fold((failure) => [], (data) {
    // Jika user belum memilih bulan (atau tab "Semua"), kembalikan hasil search apa adanya
    if (selectedMonth == null) {
      return data;
    }

    // Filter data berdasarkan Bulan yang dipilih di Tab
    return data.where((t) {
      return t.date.year == selectedMonth.year &&
          t.date.month == selectedMonth.month;
    }).toList();
  });
});

// 4. Provider Khusus untuk Mendapatkan Daftar Bulan yang Tersedia
// Gunanya untuk membuat Tab secara dinamis
final availableMonthsProvider = FutureProvider.autoDispose<List<DateTime>>((
  ref,
) async {
  // Kita ambil semua data dulu untuk dicek bulannya
  final useCase = ref.watch(searchTransactionsProvider);
  // Refresh jika ada perubahan
  ref.watch(transactionListProvider);

  final result = await useCase(''); // Ambil semua data (query kosong)

  return result.fold((failure) => [], (data) {
    // Set untuk menyimpan bulan unik (agar tidak duplikat)
    final Set<String> uniqueKeys = {};
    final List<DateTime> months = [];

    for (var t in data) {
      // Key unik: "2025-10"
      final key = "${t.date.year}-${t.date.month}";
      if (!uniqueKeys.contains(key)) {
        uniqueKeys.add(key);
        // Simpan tanggal (kita ambil tgl 1 tiap bulan sebagai perwakilan)
        months.add(DateTime(t.date.year, t.date.month, 1));
      }
    }
    return months;
  });
});

class TransactionSearchPage extends ConsumerStatefulWidget {
  const TransactionSearchPage({super.key});

  @override
  ConsumerState<TransactionSearchPage> createState() =>
      _TransactionSearchPageState();
}

class _TransactionSearchPageState extends ConsumerState<TransactionSearchPage> {
  // Flag agar kita bisa set bulan terbaru secara otomatis saat pertama buka
  bool _isFirstLoad = true;

  @override
  Widget build(BuildContext context) {
    // Data Transaksi yang sudah difilter
    final transactionsAsync = ref.watch(filteredTransactionsProvider);

    // Data List Bulan untuk Tab
    final availableMonthsAsync = ref.watch(availableMonthsProvider);

    // Text Search
    final currentQuery = ref.watch(searchQueryProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    // Controller TextField
    final searchController = TextEditingController(text: currentQuery);
    searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: searchController.text.length),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: searchController,
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).setQuery(value);
            },
            decoration: const InputDecoration(
              hintText: 'Cari transaksi...',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              contentPadding: EdgeInsets.only(top: 8),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // --- TAB BULAN (Horizontal List) ---
          Container(
            color: Colors.teal,
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: availableMonthsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (months) {
                  if (months.isEmpty) return const SizedBox.shrink();

                  // Logic: Pilih bulan terbaru saat pertama kali load
                  if (_isFirstLoad && selectedMonth == null) {
                    // Gunakan addPostFrameCallback agar tidak error saat build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (months.isNotEmpty) {
                        ref
                            .read(selectedMonthProvider.notifier)
                            .selectMonth(months.first);
                        setState(() => _isFirstLoad = false);
                      }
                    });
                  }

                  return Row(
                    children: months.map((date) {
                      final isSelected =
                          selectedMonth != null &&
                          selectedMonth.year == date.year &&
                          selectedMonth.month == date.month;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            DateFormat('MMMM yyyy', 'id_ID').format(date),
                            style: TextStyle(
                              color: isSelected ? Colors.teal : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(selectedMonthProvider.notifier)
                                  .selectMonth(date);
                            }
                          },
                          backgroundColor: Colors.teal.shade700,
                          selectedColor: Colors.white,
                          checkmarkColor: Colors.teal,
                          side: BorderSide.none, // Hilangkan border
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),

          // --- LIST TRANSAKSI ---
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak ada transaksi di bulan ini',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: transactions.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];

                    return Dismissible(
                      key: Key('search_${transaction.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.redAccent,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Hapus Transaksi?'),
                            content: const Text(
                              'Data yang dihapus tidak bisa dikembalikan.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        ref
                            .read(transactionListProvider.notifier)
                            .deleteTransaction(transaction.id!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaksi dihapus')),
                        );
                      },
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddTransactionPage(
                                transactionToEdit: transaction,
                              ),
                            ),
                          );
                        },
                        child: TransactionItem(transaction: transaction),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
