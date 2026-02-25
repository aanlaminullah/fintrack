import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/usecase_providers.dart';
import '../providers/transaction_provider.dart';
import '../../domain/entities/transaction.dart';
import '../widgets/transaction_item.dart';
import 'add_transaction_page.dart';
import '../../core/utils/currency_formatter.dart';
import '../providers/wallet_provider.dart';

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

      // AMBIL WALLET YANG AKTIF
      final currentWallet = ref.watch(selectedWalletProvider);

      // Jika tidak ada wallet aktif, return kosong (safety)
      if (currentWallet == null || currentWallet.id == null) return [];

      // Auto-refresh jika ada perubahan di list utama
      ref.watch(transactionListProvider);

      // PANGGIL USECASE DENGAN WALLET ID
      final result = await searchUseCase(query, currentWallet.id!);

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
  final currentWallet = ref.watch(selectedWalletProvider);

  if (currentWallet == null || currentWallet.id == null) return [];

  // Panggil useCase dengan query kosong & wallet ID untuk dapat semua data wallet ini
  final result = await useCase('', currentWallet.id!);

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
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
              contentPadding: EdgeInsets.zero,
              isDense: true,
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
              border: Border(bottom: BorderSide(color: Colors.black12)),
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
                                color: isSelected
                                    ? const Color.fromARGB(255, 135, 206, 173)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                DateFormat('MMM', 'id_ID').format(date),
                                style: TextStyle(
                                  color: Colors.black,
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
                          Icons.search_off, // Icon diganti biar beda
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentQuery.isEmpty
                              ? 'Tidak ada transaksi di akun ini'
                              : 'Tidak ditemukan "$currentQuery"',
                          style: TextStyle(color: Colors.grey[400]),
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

                    bool showHeader = false;
                    if (index == 0) {
                      showHeader = true;
                    } else {
                      final prevDate = transactions[index - 1].date;
                      if (!_isSameDay(transaction.date, prevDate)) {
                        showHeader = true;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader)
                          Builder(
                            builder: (context) {
                              int totalDailyExpense = transactions
                                  .where(
                                    (t) =>
                                        t.type == 'expense' &&
                                        _isSameDay(t.date, transaction.date),
                                  )
                                  .fold(0, (sum, item) => sum + item.amount);

                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  24,
                                  20,
                                  8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                        if (totalDailyExpense > 0)
                                          Text(
                                            formatRupiah(totalDailyExpense),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Divider(height: 1, thickness: 0.5),
                                  ],
                                ),
                              );
                            },
                          ),

                        Dismissible(
                          key: Key('search_${transaction.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red[50],
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
                              showDate: false,
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
