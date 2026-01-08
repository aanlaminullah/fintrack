import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/usecase_providers.dart';
import '../providers/transaction_provider.dart';
import '../../domain/entities/transaction.dart';
import '../widgets/transaction_item.dart';
import 'add_transaction_page.dart';

// 1. Notifier untuk Search Query
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

// 2. Notifier untuk Selected Month
class SelectedMonthNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;
  void selectMonth(DateTime date) => state = date;
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime?>(
      SelectedMonthNotifier.new,
    );

// 3. Provider Utama (Filter Data)
final filteredTransactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) async {
      final query = ref.watch(searchQueryProvider);
      final selectedMonth = ref.watch(selectedMonthProvider);
      final searchUseCase = ref.watch(searchTransactionsProvider);

      ref.watch(transactionListProvider); // Auto-refresh

      final result = await searchUseCase(query);

      return result.fold((failure) => <Transaction>[], (data) {
        if (selectedMonth == null) return data;
        return data.where((t) {
          return t.date.year == selectedMonth.year &&
              t.date.month == selectedMonth.month;
        }).toList();
      });
    });

// 4. Provider List Bulan
final availableMonthsProvider = FutureProvider.autoDispose<List<DateTime>>((
  ref,
) async {
  final useCase = ref.watch(searchTransactionsProvider);
  ref.watch(transactionListProvider);

  final result = await useCase('');

  return result.fold((failure) => [], (data) {
    final Set<String> uniqueKeys = {};
    final List<DateTime> months = [];
    for (var t in data) {
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

class TransactionSearchPage extends ConsumerStatefulWidget {
  const TransactionSearchPage({super.key});

  @override
  ConsumerState<TransactionSearchPage> createState() =>
      _TransactionSearchPageState();
}

class _TransactionSearchPageState extends ConsumerState<TransactionSearchPage> {
  bool _isFirstLoad = true;

  // Helper untuk mengecek apakah dua tanggal sama persis
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final availableMonthsAsync = ref.watch(availableMonthsProvider);
    final currentQuery = ref.watch(searchQueryProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    final searchController = TextEditingController(text: currentQuery);
    searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: searchController.text.length),
    );

    return Scaffold(
      backgroundColor: Colors.white, // Ubah jadi putih bersih sesuai referensi
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black, // Icon kembali jadi hitam
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100], // Background search abu sangat muda
            borderRadius: BorderRadius.circular(20), // Lebih bulat
          ),
          child: TextField(
            controller: searchController,
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).setQuery(value);
            },
            textAlignVertical: TextAlignVertical.center,
            decoration: const InputDecoration(
              hintText: 'Cari transaksi...',
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              contentPadding:
                  EdgeInsets.zero, // Ganti jadi zero atau biarkan default
              isDense: true, // Opsional: Memadatkan layout
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // --- TAB BULAN (Horizontal List) ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.black12),
              ), // Garis tipis di bawah tab
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: availableMonthsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (months) {
                  if (months.isEmpty) return const SizedBox.shrink();

                  // Auto select bulan terbaru
                  if (_isFirstLoad && selectedMonth == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (months.isNotEmpty) {
                        ref
                            .read(selectedMonthProvider.notifier)
                            .selectMonth(months.last);
                        setState(() => _isFirstLoad = false);
                      }
                    });
                  }

                  return Row(
                    children: [
                      ...months.map((date) {
                        final isSelected =
                            selectedMonth != null &&
                            selectedMonth.year == date.year &&
                            selectedMonth.month == date.month;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              ref
                                  .read(selectedMonthProvider.notifier)
                                  .selectMonth(date);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                // Warna Lime/Kuning cerah jika dipilih, abu muda jika tidak
                                color: isSelected
                                    ? const Color.fromARGB(255, 135, 206, 173)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(
                                  24,
                                ), // Bentuk Kapsul
                              ),
                              child: Text(
                                // Format Singkat: Jan, Feb, Mar
                                DateFormat('MMM', 'id_ID').format(date),
                                style: TextStyle(
                                  color: Colors.black, // Text selalu hitam
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ),

          // --- LIST TRANSAKSI DENGAN SEPARATOR ---
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak ada transaksi',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: transactions.length,
                  padding: const EdgeInsets.only(bottom: 20),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];

                    // --- LOGIC PEMBATAS TANGGAL ---
                    bool showHeader = false;
                    if (index == 0) {
                      // Item pertama pasti punya header
                      showHeader = true;
                    } else {
                      // Cek apakah tanggal item ini BEDA dengan tanggal item sebelumnya
                      final prevDate = transactions[index - 1].date;
                      if (!_isSameDay(transaction.date, prevDate)) {
                        showHeader = true;
                      }
                    }
                    // -----------------------------

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TAMPILKAN HEADER TANGGAL
                        if (showHeader)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat(
                                    'dd MMMM yyyy',
                                    'id_ID',
                                  ).format(transaction.date),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Divider(
                                  height: 1,
                                  thickness: 0.5,
                                ), // Garis tipis pembatas
                              ],
                            ),
                          ),

                        // ITEM TRANSAKSI (SWIPEABLE)
                        Dismissible(
                          key: Key('search_${transaction.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red[50], // Merah muda lembut
                            child: const Icon(Icons.delete, color: Colors.red),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Hapus?'),
                                content: const Text(
                                  'Data tidak bisa dikembalikan.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text(
                                      'Hapus',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (_) {
                            ref
                                .read(transactionListProvider.notifier)
                                .deleteTransaction(transaction.id!);
                          },
                          child: InkWell(
                            // Ganti GestureDetector jadi InkWell biar ada efek klik
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
                            child: TransactionItem(
                              transaction: transaction,
                              // Opsional: Buat TransactionItem lebih flat (tanpa card shadow)
                              // jika ingin persis seperti gambar
                            ),
                          ),
                        ),
                      ],
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
