import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../pages/budget_detail_page.dart';
import '../providers/flex_budget_provider.dart';

class BudgetSummaryWidget extends ConsumerWidget {
  final List<Transaction> transactions;
  final List<Category> categories;

  const BudgetSummaryWidget({
    super.key,
    required this.transactions,
    required this.categories,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Filter Kategori yang punya budget
    final budgetedCategories = categories.where((c) => c.budget > 0).toList();

    // Ambil Data Flex Budget
    final flexBudgetState = ref.watch(flexBudgetCalculationProvider);

    // Hitung Total Fixed Budget & Expense
    final now = DateTime.now();
    int fixedBudget = 0;
    int fixedExpense = 0;

    for (var cat in budgetedCategories) {
      fixedBudget += cat.budget;

      // Hitung expense hanya untuk kategori ini di bulan ini
      final catExpense = transactions
          .where((t) {
            DateTime tDate;
            try {
              tDate = t.date;
            } catch (_) {
              tDate = DateTime.parse(t.date.toString());
            }

            return t.categoryId == cat.id &&
                t.type == 'expense' &&
                tDate.month == now.month &&
                tDate.year == now.year;
          })
          .fold(0, (sum, t) => sum + t.amount);

      fixedExpense += catExpense;
    }

    // --- UPDATE LOGIC TOTAL: GABUNGAN FIXED + FLEX ---
    final int totalBudget = fixedBudget + flexBudgetState.limit;
    final int totalExpense = fixedExpense + flexBudgetState.used;

    // Jika tidak ada budget sama sekali (dan flex 0), sembunyikan
    if (totalBudget == 0) return const SizedBox.shrink();

    double percentage = totalBudget == 0 ? 0 : totalExpense / totalBudget;
    // Cap percentage max 1.0 agar tidak error render bar
    double progressValue = percentage > 1.0 ? 1.0 : percentage;

    // Hitung Sisa
    final int remaining = totalBudget - totalExpense;

    // Tentukan Warna Global Status
    Color statusColor;
    if (percentage >= 1.0) {
      statusColor = Colors.red;
    } else if (percentage >= 0.75) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.teal;
    }

    // Warna teks persentase (Putih jika bar penuh/gelap, Hitam jika bar kosong/terang)
    final Color percentTextColor = percentage > 0.5
        ? Colors.white
        : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BudgetDetailPage(
                  transactions: transactions,
                  categories: categories,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Budget Bulanan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Bar dengan Persentase di Tengah (Stack)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 20, // Bar diperbesar
                        backgroundColor: Colors.grey[200],
                        color: statusColor,
                      ),
                    ),
                    Text(
                      '${(percentage * 100).toInt()}%',
                      style: TextStyle(
                        color: percentTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Info Bawah: Terpakai/Limit (Kiri) & Sisa (Kanan)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Kiri: 50.000 / 100.000
                    Text(
                      '${_formatNumber(totalExpense)} / ${_formatNumber(totalBudget)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Kanan: Sisa / Over
                    Text(
                      remaining < 0
                          ? 'Over: ${_formatNumber(remaining.abs())}'
                          : 'Sisa: ${_formatNumber(remaining)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: remaining < 0 ? Colors.red : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Format Angka Biasa (1.500.000) tanpa simbol Rp agar hemat tempat
  String _formatNumber(int number) {
    return NumberFormat.decimalPattern('id_ID').format(number);
  }
}
