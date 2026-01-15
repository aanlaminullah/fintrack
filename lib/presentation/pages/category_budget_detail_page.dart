import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/category.dart';
import '../../core/utils/app_icons.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/transaction_item.dart';
import '../providers/usecase_providers.dart';

class CategoryBudgetDetailPage extends ConsumerWidget {
  final Category category;

  const CategoryBudgetDetailPage({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kita listen ke categoryListProvider untuk mendapatkan update terbaru dari kategori ini
    // (misal jika user toggle bulanan/mingguan di halaman ini)
    final categoryListState = ref.watch(categoryListProvider);
    final currentCategory =
        categoryListState.value?.cast<Category>().firstWhere(
          (c) => c.id == category.id,
          orElse: () => category,
        ) ??
        category;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(currentCategory.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. KARTU BUDGET ---
            _buildBudgetCard(context, ref, currentCategory),

            const SizedBox(height: 24),

            // --- 2. RIWAYAT PENGELUARAN ---
            const Text(
              "Riwayat Pengeluaran",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            _buildTransactionList(ref, currentCategory),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) {
    final transactionState = ref.watch(transactionListProvider);
    final transactions = transactionState.value ?? [];

    final bool isWeekly = category.isWeekly;
    final now = DateTime.now();
    int limit = 0;
    int expense = 0;

    if (isWeekly) {
      // --- MODE MINGGUAN ---
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      double rawWeekly = (category.budget / daysInMonth) * 7;
      limit = (rawWeekly / 1000).floor() * 1000;

      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      final start = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
      final end = DateTime(
        endOfWeek.year,
        endOfWeek.month,
        endOfWeek.day,
        23,
        59,
        59,
      );

      expense = transactions
          .where((t) {
            DateTime tDate;
            try {
              tDate = t.date;
            } catch (_) {
              tDate = DateTime.parse(t.date.toString());
            }

            return t.categoryId == category.id &&
                t.type == 'expense' &&
                tDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
                tDate.isBefore(end.add(const Duration(seconds: 1)));
          })
          .fold(0, (sum, t) => sum + t.amount);
    } else {
      // --- MODE BULANAN ---
      limit = category.budget;
      expense = transactions
          .where((t) {
            DateTime tDate;
            try {
              tDate = t.date;
            } catch (_) {
              tDate = DateTime.parse(t.date.toString());
            }

            return t.categoryId == category.id &&
                t.type == 'expense' &&
                tDate.month == now.month &&
                tDate.year == now.year;
          })
          .fold(0, (sum, t) => sum + t.amount);
    }

    final double percentage = limit == 0 ? 0 : expense / limit;
    final int remaining = limit - expense;
    final double progressValue = percentage > 1.0 ? 1.0 : percentage;

    // --- LOGIKA STATUS WARNA & LABEL ---
    Color statusColor;
    String statusText;

    if (expense > limit) {
      statusColor = Colors.red;
      statusText = "Over";
    } else if (expense == limit && limit > 0) {
      statusColor = Colors.red;
      statusText = "Full";
    } else if (percentage >= 0.75) {
      statusColor = Colors.orange;
      statusText = "Waspada";
    } else {
      statusColor = Colors.green;
      statusText = "Aman";
    }

    final Color percentTextColor = percentage > 0.5
        ? Colors.white
        : Colors.black87;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // BARIS ATAS
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(category.color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.getIcon(category.icon),
                  color: Color(category.color),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      isWeekly ? 'Budget Mingguan' : 'Budget Bulanan',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        final updatedCategory = category.copyWith(
                          isWeekly: !category.isWeekly,
                        );
                        await ref.read(updateCategoryProvider)(updatedCategory);
                        ref.invalidate(categoryListProvider);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isWeekly
                              ? Colors.teal.shade50
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isWeekly ? Colors.teal : Colors.blue,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isWeekly
                                  ? Icons.calendar_view_week
                                  : Icons.calendar_view_month,
                              size: 16,
                              color: isWeekly ? Colors.teal : Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isWeekly ? 'Mingguan' : 'Bulanan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isWeekly ? Colors.teal : Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
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
            ],
          ),

          const SizedBox(height: 24),

          // PROGRESS BAR
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: Colors.grey[200],
                  color: statusColor,
                  minHeight: 24,
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

          const SizedBox(height: 16),

          // INFO BAWAH
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
                    _formatRupiah(expense),
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    remaining < 0 ? "Over Budget" : "Sisa Budget",
                    style: TextStyle(
                      fontSize: 12,
                      color: remaining < 0 ? Colors.red : Colors.grey,
                    ),
                  ),
                  Text(
                    _formatRupiah(remaining.abs()),
                    style: TextStyle(
                      color: remaining < 0 ? Colors.red : Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(WidgetRef ref, Category category) {
    final transactionState = ref.watch(transactionListProvider);

    return transactionState.when(
      data: (transactions) {
        final now = DateTime.now();

        // Filter Transaksi: Kategori ini + Expense + Bulan ini
        // (Kita tampilkan semua transaksi bulan ini even if budget mingguan,
        // atau kita filter sesuai budget settings?
        // User request: "riwayat pengeluaran di kategori itu".
        // Biasanya user expect semua history bulan ini.)

        final filteredTransactions = transactions.where((t) {
          DateTime tDate;
          try {
            tDate = t.date;
          } catch (_) {
            tDate = DateTime.parse(t.date.toString());
          }

          final isCategoryMatch = t.categoryId == category.id;
          final isExpense = t.type == 'expense';

          if (category.isWeekly) {
            // Filter Mingguan
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final endOfWeek = startOfWeek.add(const Duration(days: 6));
            final start = DateTime(
              startOfWeek.year,
              startOfWeek.month,
              startOfWeek.day,
            );
            final end = DateTime(
              endOfWeek.year,
              endOfWeek.month,
              endOfWeek.day,
              23,
              59,
              59,
            );

            return isCategoryMatch &&
                isExpense &&
                tDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
                tDate.isBefore(end.add(const Duration(seconds: 1)));
          } else {
            // Filter Bulanan
            return isCategoryMatch &&
                isExpense &&
                tDate.month == now.month &&
                tDate.year == now.year;
          }
        }).toList();

        if (filteredTransactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 40, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text(
                    "Belum ada transaksi bulan ini",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
          );
        }

        // Urutkan tanggal terbaru
        filteredTransactions.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredTransactions.length,
          itemBuilder: (context, index) {
            final transaction = filteredTransactions[index];

            // --- LOGIC PEMBATAS TANGGAL ---
            bool showHeader = false;
            if (index == 0) {
              showHeader = true;
            } else {
              final prevDate = filteredTransactions[index - 1].date;
              if (!_isSameDay(transaction.date, prevDate)) {
                showHeader = true;
              }
            }
            // -----------------------------

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TAMPILKAN HEADER TANGGAL & TOTAL
                if (showHeader)
                  Builder(
                    builder: (context) {
                      // --- 2. HITUNG TOTAL PENGELUARAN HARI INI ---
                      int totalDailyExpense = filteredTransactions
                          .where((t) => _isSameDay(t.date, transaction.date))
                          .fold(0, (sum, item) => sum + item.amount);

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(
                          0, // padding disesuaikan agar rapi dlm Container parent
                          24,
                          0,
                          8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // TANGGAL (Kiri)
                                Text(
                                  DateFormat(
                                    'dd MMMM yyyy',
                                    'id_ID',
                                  ).format(transaction.date),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),

                                // TOTAL (Kanan)
                                Text(
                                  _formatRupiah(totalDailyExpense),
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

                // ITEM TRANSAKSI
                TransactionItem(transaction: transaction),
              ],
            );
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
