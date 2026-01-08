import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/app_icons.dart';
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
  // State untuk Filter Kategori (null = Tampilkan Semua)
  String? _selectedCategoryName;

  // State untuk Sortir Amount (true = Terbesar ke Terkecil, false = Terkecil ke Terbesar)
  bool _isSortDesc = true;

  @override
  Widget build(BuildContext context) {
    // 1. Ambil Data Chart (Group by Category)
    final chartDataAsync = ref.watch(expenseByCategoryProvider);

    // 2. Ambil Data Semua Transaksi (Untuk List di bawah)
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
            // --- 1. CHART SECTION (DIPERBAIKI) ---
            Container(
              color: Colors.white,
              width: double.infinity,
              height: 300, // <--- PERBAIKAN: WAJIB ADA HEIGHT
              padding: const EdgeInsets.only(bottom: 20),
              child: const ExpensePieChart(),
            ),

            const SizedBox(height: 10),

            // --- 2. FILTER & SORT SECTION ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Filter
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

                        // TOMBOL SORT AMOUNT
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isSortDesc = !_isSortDesc;
                            });
                          },
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
                                  _isSortDesc
                                      ? Icons.sort
                                      : Icons.filter_list, // Icon berubah
                                  size: 16,
                                  color: Colors.black87,
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

                  // TAB KATEGORI (Horizontal Scroll)
                  chartDataAsync.when(
                    loading: () => const SizedBox(height: 40),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (data) {
                      if (data.isEmpty) return const SizedBox.shrink();

                      // Kita ambil key map (Format: "Nama|Color")
                      final categoryKeys = data.keys.toList();

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            // TAB "SEMUA"
                            _buildTabItem(
                              label: 'Semua',
                              isSelected: _selectedCategoryName == null,
                              onTap: () =>
                                  setState(() => _selectedCategoryName = null),
                            ),

                            // TAB KATEGORI LAINNYA
                            ...categoryKeys.map((key) {
                              final split = key.split('|');
                              final name = split[0];
                              // final color = int.tryParse(split[1]) ?? 0xFF9E9E9E; // Jika butuh warna

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
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // --- 3. LIST TRANSAKSI HASIL FILTER ---
            allTransactionsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (transactions) {
                // 1. Filter hanya tipe 'expense' (karena ini analisis pengeluaran)
                var filteredList = transactions
                    .where((t) => t.type == 'expense')
                    .toList();

                // 2. Filter berdasarkan Kategori (Jika ada yg dipilih)
                if (_selectedCategoryName != null) {
                  filteredList = filteredList
                      .where((t) => t.category?.name == _selectedCategoryName)
                      .toList();
                }

                // 3. Sort berdasarkan Jumlah (Amount)
                filteredList.sort((a, b) {
                  if (_isSortDesc) {
                    return b.amount.compareTo(a.amount); // Besar ke Kecil
                  } else {
                    return a.amount.compareTo(b.amount); // Kecil ke Besar
                  }
                });

                if (filteredList.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Text(
                        'Tidak ada transaksi sesuai filter.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
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
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget Helper untuk Tab Kapsul (Sama style dengan search page)
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
            // Warna Hijau Lime jika dipilih, Abu muda jika tidak
            color: isSelected
                ? const Color.fromARGB(255, 135, 206, 173)
                : Colors.grey[200],
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
