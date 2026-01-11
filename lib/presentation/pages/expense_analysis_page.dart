import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/currency_formatter.dart';
import '../providers/chart_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/transaction_item.dart';
import 'add_transaction_page.dart';

class ExpenseAnalysisPage extends ConsumerStatefulWidget {
  const ExpenseAnalysisPage({super.key});

  @override
  ConsumerState<ExpenseAnalysisPage> createState() =>
      _ExpenseAnalysisPageState();
}

class _ExpenseAnalysisPageState extends ConsumerState<ExpenseAnalysisPage> {
  String? _selectedCategoryName;
  bool _isSortDesc = true;
  bool _isFirstLoad = true;

  @override
  Widget build(BuildContext context) {
    // 1. Ambil Data Chart (Sesuai Bulan Selected)
    final chartDataAsync = ref.watch(monthlyChartProvider);

    // 2. Ambil List Bulan yang Tersedia
    final availableMonthsAsync = ref.watch(availableMonthsAnalysisProvider);

    // 3. Ambil Tanggal yang Sedang Dipilih
    final selectedDate = ref.watch(analysisDateProvider);

    // 4. Ambil Semua Transaksi untuk List di Bawah
    final allTransactionsAsync = ref.watch(transactionListProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Analisis Pengeluaran'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 0. TAB BULAN (MONTH PICKER) ---
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: availableMonthsAsync.when(
                  data: (months) {
                    if (months.isEmpty) return const SizedBox.shrink();

                    // Auto select bulan terbaru saat pertama buka
                    if (_isFirstLoad) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => _isFirstLoad = false);
                        }
                      });
                    }

                    return Row(
                      children: months.map((date) {
                        final isSelected =
                            date.year == selectedDate.year &&
                            date.month == selectedDate.month;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              // Update Provider Tanggal (Gunakan method setDate)
                              ref
                                  .read(analysisDateProvider.notifier)
                                  .setDate(date);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.teal
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                DateFormat('MMM yyyy', 'id_ID').format(date),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const SizedBox(height: 40),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // --- 1. CHART SECTION ---
            Container(
              color: Colors.white,
              width: double.infinity,
              height: 300,
              padding: const EdgeInsets.only(bottom: 20),
              // Pass data dari provider monthlyChartProvider
              child: ExpensePieChart(chartData: chartDataAsync),
            ),

            const SizedBox(height: 10),

            // --- 2. FILTER & SORT SECTION ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Kategori',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              setState(() => _isSortDesc = !_isSortDesc),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isSortDesc ? Icons.sort : Icons.filter_list,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isSortDesc ? 'Terbesar' : 'Terkecil',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // TAB KATEGORI
                  chartDataAsync.when(
                    data: (data) {
                      if (data.isEmpty) return const SizedBox.shrink();
                      final categoryKeys = data.keys.toList();
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _buildTabItem(
                              label: 'Semua',
                              isSelected: _selectedCategoryName == null,
                              onTap: () =>
                                  setState(() => _selectedCategoryName = null),
                            ),
                            ...categoryKeys.map((key) {
                              final split = key.split('|');
                              final name = split[0];
                              return _buildTabItem(
                                label: name,
                                isSelected: _selectedCategoryName == name,
                                onTap: () => setState(
                                  () => _selectedCategoryName = name,
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox(height: 40),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // --- 3. LIST TRANSAKSI (FILTERED BY DATE & CATEGORY) ---
            allTransactionsAsync.when(
              data: (transactions) {
                // FILTER 1: Hanya Expense
                var filteredList = transactions
                    .where((t) => t.type == 'expense')
                    .toList();

                // FILTER 2: Hanya Bulan & Tahun yang Dipilih
                filteredList = filteredList
                    .where(
                      (t) =>
                          t.date.year == selectedDate.year &&
                          t.date.month == selectedDate.month,
                    )
                    .toList();

                // FILTER 3: Kategori (Jika dipilih)
                if (_selectedCategoryName != null) {
                  filteredList = filteredList
                      .where((t) => t.category?.name == _selectedCategoryName)
                      .toList();
                }

                // SORTING
                filteredList.sort((a, b) {
                  if (_isSortDesc) return b.amount.compareTo(a.amount);
                  return a.amount.compareTo(b.amount);
                });

                // HITUNG TOTAL
                final int totalFilteredAmount = filteredList.fold(
                  0,
                  (sum, item) => sum + item.amount,
                );

                return Column(
                  children: [
                    // TOTAL CARD
                    if (filteredList.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.teal.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedCategoryName != null
                                  ? 'Total $_selectedCategoryName'
                                  : 'Total Pengeluaran',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            Text(
                              formatRupiah(totalFilteredAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // LIST ITEMS
                    if (filteredList.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Text(
                            'Tidak ada pengeluaran di periode ini.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredList[index];
                          return InkWell(
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
                          );
                        },
                      ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD4E157) : Colors.grey[200],
            borderRadius: BorderRadius.circular(24),
            border: isSelected
                ? Border.all(color: Colors.teal.withOpacity(0.2))
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
