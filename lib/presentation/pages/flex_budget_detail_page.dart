import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/app_icons.dart';
import '../providers/category_provider.dart';
import '../providers/flex_budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_item.dart';

class FlexBudgetDetailPage extends ConsumerWidget {
  const FlexBudgetDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flexState = ref.watch(flexBudgetCalculationProvider);
    final allCategories = ref.watch(categoryListProvider).value ?? [];
    final selectedIncomeIds = ref.watch(flexIncomeSettingsProvider);

    // Filter Kategori Income untuk Settings
    final incomeCategories = allCategories
        .where((c) => c.type == 'income')
        .toList();

    // Logic Warna Status
    Color statusColor = Colors.teal;
    String statusText = "Aman";
    if (flexState.percentage >= 1.0) {
      statusColor = Colors.red;
      statusText = "Over Limit";
    } else if (flexState.percentage >= 0.75) {
      statusColor = Colors.orange;
      statusText = "Waspada";
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Flex Budget'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. KARTU UTAMA FLEX ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Flex Budget",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Dana Bebas",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Progress Bar Besar
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: flexState.percentage,
                          minHeight: 24,
                          backgroundColor: Colors.grey[200],
                          color: statusColor,
                        ),
                      ),
                      Text(
                        "${(flexState.percentage * 100).toInt()}%",
                        style: TextStyle(
                          color: flexState.percentage > 0.5
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Terpakai",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            _formatRupiah(flexState.used),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Batas Maksimal",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            _formatRupiah(flexState.limit),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 2. PENGATURAN SUMBER PEMASUKAN ---
            const Text(
              "Sumber Pemasukan Flex",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ExpansionTile(
                title: const Text(
                  "Pilih Pendapatan",
                  style: TextStyle(fontSize: 14),
                ),
                subtitle: const Text(
                  "Tentukan gaji/pemasukan mana yang dihitung",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                leading: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.teal,
                ),
                children: incomeCategories.map((cat) {
                  // Cek apakah ID terpilih.
                  // Logic Khusus: Jika settings kosong DAN namanya mengandung 'gaji', anggap true (default visual)
                  // Tapi lebih aman pakai logic provider murni.
                  bool isChecked = false;
                  if (selectedIncomeIds.isEmpty) {
                    // Fallback default visual
                    isChecked =
                        cat.name.toLowerCase().contains('gaji') ||
                        cat.name.toLowerCase().contains('salary');
                    // Jika tidak ada yg namanya gaji, check yang pertama
                    if (!isChecked &&
                        incomeCategories.isNotEmpty &&
                        cat == incomeCategories.first) {
                      isChecked = true;
                    }
                  } else {
                    isChecked = selectedIncomeIds.contains(cat.id.toString());
                  }

                  return CheckboxListTile(
                    title: Text(cat.name),
                    secondary: Icon(
                      AppIcons.getIcon(cat.icon),
                      color: Color(cat.color),
                    ),
                    value: isChecked,
                    activeColor: Colors.teal,
                    onChanged: (bool? value) {
                      if (cat.id != null) {
                        ref
                            .read(flexIncomeSettingsProvider.notifier)
                            .toggleSource(cat.id.toString());
                      }
                    },
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // --- 3. LIST TRANSAKSI FLEX (NON-BUDGET) ---
            const Text(
              "Riwayat Pengeluaran Flex",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            _buildFlexTransactionsList(ref, allCategories),
          ],
        ),
      ),
    );
  }

  Widget _buildFlexTransactionsList(
    WidgetRef ref,
    List<dynamic> allCategories,
  ) {
    final transactionState = ref.watch(transactionListProvider);

    // Ambil ID kategori yang PUNYA budget (Fixed)
    final budgetedCategoryIds = allCategories
        .where((c) => c.type == 'expense' && c.budget > 0)
        .map((c) => c.id)
        .toSet();

    return transactionState.when(
      data: (transactions) {
        final now = DateTime.now();
        // Filter: Transaksi Bulan Ini + Tipe Expense + Kategori TIDAK punya budget
        final flexTransactions = transactions.where((t) {
          DateTime tDate;
          try {
            tDate = t.date;
          } catch (_) {
            tDate = DateTime.parse(t.date.toString());
          }

          return t.type == 'expense' &&
              tDate.month == now.month &&
              tDate.year == now.year &&
              !budgetedCategoryIds.contains(t.categoryId);
        }).toList();

        if (flexTransactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 40,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Belum ada pengeluaran Flex",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // Urutkan tanggal terbaru
        flexTransactions.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: flexTransactions.length,
          itemBuilder: (context, index) {
            return TransactionItem(transaction: flexTransactions[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _formatRupiah(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }
}
