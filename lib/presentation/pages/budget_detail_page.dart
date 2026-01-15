import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../../core/utils/app_icons.dart';
import '../providers/category_provider.dart';
import '../providers/usecase_providers.dart';
import '../providers/flex_budget_provider.dart'; // Import Provider
import 'flex_budget_detail_page.dart'; // Import Page
import 'category_budget_detail_page.dart'; // Import Details Page

class BudgetDetailPage extends ConsumerStatefulWidget {
  final List<Transaction> transactions;
  final List<Category> categories;

  const BudgetDetailPage({
    super.key,
    required this.transactions,
    required this.categories,
  });

  @override
  ConsumerState<BudgetDetailPage> createState() => _BudgetDetailPageState();
}

class _BudgetDetailPageState extends ConsumerState<BudgetDetailPage> {
  @override
  Widget build(BuildContext context) {
    final categoryListState = ref.watch(categoryListProvider);
    final flexState = ref.watch(flexBudgetCalculationProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Detail Anggaran'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: categoryListState.when(
        data: (latestCategories) {
          var budgetedCategories = latestCategories
              .where((c) => c.budget > 0)
              .toList();

          budgetedCategories.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));

          // KITA AKAN MERENDER 1 ITEM TAMBAHAN (FLEX) + LIST KATEGORI FIXED
          final totalItemCount = budgetedCategories.length + 1;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: totalItemCount,
            itemBuilder: (context, index) {
              // --- ITEM 0: FLEX BUDGET CARD (KHUSUS) ---
              if (index == 0) {
                return _buildFlexBudgetCard(context, flexState);
              }

              // --- ITEM SELANJUTNYA: KATEGORI BIASA ---
              // Index dikurangi 1 karena index 0 dipakai Flex
              final category = budgetedCategories[index - 1];
              return _buildBudgetCard(category, widget.transactions);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  // --- WIDGET CARD KHUSUS FLEX BUDGET ---
  Widget _buildFlexBudgetCard(BuildContext context, FlexBudgetState state) {
    Color statusColor = Colors.teal;
    if (state.percentage >= 1.0) {
      statusColor = Colors.red;
    } else if (state.percentage >= 0.75) {
      statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color:
            Colors.white, // Bisa diganti warna spesial misal Colors.indigo[50]
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.indigo.withOpacity(0.5),
          width: 1.5,
        ), // Border pembeda
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // NAVIGASI KE FLEX DETAIL
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FlexBudgetDetailPage()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Flex Budget",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.indigo,
                            ),
                          ),
                          Text(
                            'Batas Dinamis: ${_formatRupiah(state.limit)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: state.percentage,
                        backgroundColor: Colors.grey[200],
                        color: statusColor,
                        minHeight: 20,
                      ),
                    ),
                    Text(
                      '${(state.percentage * 100).toInt()}%',
                      style: TextStyle(
                        color: state.percentage > 0.5
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatNumber(state.used)} / ${_formatNumber(state.limit)}',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      state.remaining < 0
                          ? 'Over: ${_formatNumber(state.remaining.abs())}'
                          : 'Sisa: ${_formatNumber(state.remaining)}',
                      style: TextStyle(
                        color: state.remaining < 0
                            ? Colors.red
                            : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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

  Widget _buildBudgetCard(Category category, List<Transaction> transactions) {
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
    final int remaining = limit - expense; // <--- INI YANG TADI HILANG
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
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
                builder: (_) => CategoryBudgetDetailPage(category: category),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // BARIS ATAS
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Color(category.color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        AppIcons.getIcon(category.icon),
                        color: Color(category.color),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
                              await ref.read(updateCategoryProvider)(
                                updatedCategory,
                              );
                              ref.invalidate(categoryListProvider);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
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
                                    size: 14,
                                    color: isWeekly ? Colors.teal : Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isWeekly ? 'Mingguan' : 'Bulanan',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isWeekly
                                          ? Colors.teal
                                          : Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 4),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // PROGRESS BAR
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        backgroundColor: Colors.grey[200],
                        color: statusColor,
                        minHeight: 20,
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

                // INFO BAWAH
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatNumber(expense)} / ${_formatNumber(limit)}',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),

                    Text(
                      remaining < 0
                          ? 'Over: ${_formatNumber(remaining.abs())}'
                          : 'Sisa: ${_formatNumber(remaining)}',
                      style: TextStyle(
                        color: remaining < 0 ? Colors.red : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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

  String _formatNumber(int number) {
    return NumberFormat.decimalPattern('id_ID').format(number);
  }

  String _formatRupiah(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }
}
