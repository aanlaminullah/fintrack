import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:intl/intl.dart';

import '../../domain/entities/category.dart';
import '../../core/utils/app_icons.dart';
import '../providers/category_provider.dart';
import '../providers/flex_budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_item.dart';

// --- Provider Lokal untuk Filter Kategori Flex ---
class FlexBudgetCategoryFilterNotifier extends StateNotifier<int?> {
  FlexBudgetCategoryFilterNotifier() : super(null);
  void selectCategory(int? id) => state = id;
}

final flexBudgetCategoryFilterProvider =
    StateNotifierProvider.autoDispose<FlexBudgetCategoryFilterNotifier, int?>((
      ref,
    ) {
      return FlexBudgetCategoryFilterNotifier();
    });

class FlexBudgetDetailPage extends ConsumerWidget {
  const FlexBudgetDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flexState = ref.watch(flexBudgetCalculationProvider);
    final allCategories = (ref.watch(categoryListProvider).value ?? [])
        .cast<Category>()
        .toList();
    final selectedIncomeIds = ref.watch(flexIncomeSettingsProvider);

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
                  "Pilih transaksi income yang dihitung Flex",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                leading: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.teal,
                ),
                children: _buildIncomeTransactionList(
                  ref,
                  allCategories.cast<Category>().toList(),
                  selectedIncomeIds,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- 3. LIST TRANSAKSI FLEX (NON-BUDGET) ---
            const Text(
              "Riwayat Pengeluaran Flex",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

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
    final selectedCategoryId = ref.watch(flexBudgetCategoryFilterProvider);

    // Ambil ID kategori yang PUNYA budget (Fixed) -> Agar tidak masuk flex
    final budgetedCategoryIds = allCategories
        .where((c) => c.type == 'expense' && c.budget > 0)
        .map((c) => c.id)
        .toSet();

    return transactionState.when(
      data: (transactions) {
        final now = DateTime.now();
        // 1. Ambil Semua Transaksi Flex Bulan Ini
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

        // 2. Grouping untuk Tab
        final Map<int, List<dynamic>> groupedTransactions = {};
        for (var t in flexTransactions) {
          if (!groupedTransactions.containsKey(t.categoryId)) {
            groupedTransactions[t.categoryId] = [];
          }
          groupedTransactions[t.categoryId]!.add(t);
        }

        // 3. Sort Keys Kategori berdasarkan Total Amount Terbesar
        final sortedCategoryKeys = groupedTransactions.keys.toList();
        sortedCategoryKeys.sort((a, b) {
          final totalA = groupedTransactions[a]!.fold(
            0,
            (sum, t) => sum + (t.amount as int),
          );
          final totalB = groupedTransactions[b]!.fold(
            0,
            (sum, t) => sum + (t.amount as int),
          );
          return totalB.compareTo(totalA); // Descending
        });

        // 4. FILTER LIST BERDASARKAN TAB YANG DIPILIH
        List<dynamic> cachedDisplayList;
        if (selectedCategoryId == null) {
          cachedDisplayList = flexTransactions;
        } else {
          cachedDisplayList = groupedTransactions[selectedCategoryId] ?? [];
        }
        // Sort by Date Descending
        cachedDisplayList.sort((a, b) => b.date.compareTo(a.date));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TABS (Scrollable) ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Tab 'Semua'
                  _buildTabItem(
                    label: 'Semua',
                    isSelected: selectedCategoryId == null,
                    onTap: () {
                      ref
                          .read(flexBudgetCategoryFilterProvider.notifier)
                          .selectCategory(null);
                    },
                  ),
                  // Tab Kategori Lainnya
                  ...sortedCategoryKeys.map((catId) {
                    final category = allCategories.firstWhere(
                      (c) => c.id == catId,
                      orElse: () => const Category(
                        id: 0,
                        name: 'Lainnya',
                        icon: 'help',
                        color: 0xFF9E9E9E,
                        type: 'expense',
                      ),
                    );

                    return _buildTabItem(
                      label: category.name,
                      isSelected: selectedCategoryId == catId,
                      onTap: () {
                        ref
                            .read(flexBudgetCategoryFilterProvider.notifier)
                            .selectCategory(catId);
                      },
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- TOTAL SUMMARY CARD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedCategoryId != null
                        ? 'Total ${allCategories.firstWhere(
                            (c) => c.id == selectedCategoryId,
                            orElse: () => const Category(id: 0, name: 'Lainnya', icon: 'help', color: 0, type: ''),
                          ).name}'
                        : 'Total Pengeluaran Flex',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  Text(
                    _formatRupiah(
                      cachedDisplayList.fold(
                        0,
                        (sum, t) => sum + (t.amount as int),
                      ),
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- LIST TRANSAKSI ---
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cachedDisplayList.length,
              itemBuilder: (context, index) {
                return TransactionItem(transaction: cachedDisplayList[index]);
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
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
            color: isSelected ? const Color(0xFFD4E157) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFC0CA33)
                  : Colors.grey.shade300,
            ),
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

  List<Widget> _buildIncomeTransactionList(
    WidgetRef ref,
    List<Category> allCategories,
    List<String> selectedIncomeIds,
  ) {
    final transactionState = ref.watch(transactionListProvider);
    final now = DateTime.now();

    return transactionState.when(
      data: (transactions) {
        // Filter income transactions for current month
        final incomeTransactions = transactions.where((t) {
          DateTime tDate;
          try {
            tDate = t.date;
          } catch (_) {
            tDate = DateTime.parse(t.date.toString());
          }
          final isMonthMatch =
              tDate.month == now.month && tDate.year == now.year;
          return t.type == 'income' && isMonthMatch;
        }).toList();

        if (incomeTransactions.isEmpty) {
          return [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Belum ada transaksi pemasukan bulan ini.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ];
        }

        // Sort by date descending
        incomeTransactions.sort((a, b) => b.date.compareTo(a.date));

        return incomeTransactions.map((t) {
          final category = allCategories.firstWhere(
            (c) => c.id == t.categoryId,
            orElse: () => const Category(
              id: 0,
              name: 'Unknown',
              icon: 'help',
              color: 0xFF9E9E9E,
              type: 'income',
            ),
          );

          final isGaji =
              category.name.toLowerCase().contains('gaji') ||
              category.name.toLowerCase().contains('salary');

          // Jika Gaji, paksa checked (true). Jika bukan, ikuti setting.
          final isChecked =
              isGaji || selectedIncomeIds.contains(t.id.toString());

          return CheckboxListTile(
            title: Text(t.title.isNotEmpty ? t.title : category.name),
            subtitle: Text(
              "${DateFormat('dd MMM').format(t.date)} • ${category.name}",
            ),
            secondary: Text(
              _formatRupiah(t.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            value: isChecked,
            activeColor: Colors.teal,
            // Jika Gaji, disable (null). Jika bukan, allow toggle.
            onChanged: isGaji
                ? null
                : (bool? value) {
                    if (t.id != null) {
                      ref
                          .read(flexIncomeSettingsProvider.notifier)
                          .toggleSource(t.id.toString());
                    }
                  },
          );
        }).toList();
      },
      loading: () => [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        ),
      ],
      error: (_, __) => [const SizedBox.shrink()],
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
