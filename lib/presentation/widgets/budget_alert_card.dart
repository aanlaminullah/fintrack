import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../../core/utils/app_icons.dart';

class BudgetAlertCard extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Category> categories;

  const BudgetAlertCard({
    super.key,
    required this.transactions,
    required this.categories,
  });

  @override
  State<BudgetAlertCard> createState() => _BudgetAlertCardState();
}

class _BudgetAlertCardState extends State<BudgetAlertCard> {
  bool _isWeekly = false; // Default: Bulanan

  @override
  Widget build(BuildContext context) {
    // 1. Ambil kategori yang punya budget (> 0)
    var budgetedCategories = widget.categories
        .where((c) => c.budget > 0)
        .toList();

    // SORTING: Newest to Oldest (ID Besar ke Kecil)
    // Asumsi ID Auto Increment
    budgetedCategories.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

    // Kalau tidak ada budget, tampilkan placeholder agar carousel tidak kosong jelek
    if (budgetedCategories.isEmpty) {
      return _buildEmptyCard();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        // Shadow agar mirip SummaryCard tapi putih
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: Judul & Toggle Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Monitoring',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              // Tombol Toggle Kecil
              InkWell(
                onTap: () {
                  setState(() {
                    _isWeekly = !_isWeekly;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _isWeekly
                        ? Colors.teal.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isWeekly
                          ? Colors.teal.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Text(
                    _isWeekly ? 'Mingguan' : 'Bulanan',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _isWeekly ? Colors.teal[700] : Colors.blue[700],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 16),

          // LIST VERTICAL
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: budgetedCategories.length,
              itemBuilder: (context, index) {
                final cat = budgetedCategories[index];
                return _buildListItem(cat);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(Category category) {
    // --- LOGIKA HITUNGAN ---
    final now = DateTime.now();
    int limit = 0;
    int expense = 0;

    if (_isWeekly) {
      // MODE MINGGUAN
      // 1. Hitung Limit Mingguan (Budget / Hari di Bulan Ini * 7)
      final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
      limit = ((category.budget / daysInMonth) * 7).floor();

      // 2. Hitung Pengeluaran Minggu Ini (Senin - Minggu)
      // Cari tanggal awal minggu (Senin)
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      // Normalisasi jam agar akurat
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

      expense = widget.transactions
          .where((t) {
            DateTime tDate = t.date; // Transaction sudah DateTime
            return t.categoryId == category.id &&
                t.type == 'expense' &&
                tDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
                tDate.isBefore(end.add(const Duration(seconds: 1)));
          })
          .fold(0, (sum, t) => sum + t.amount);
    } else {
      // MODE BULANAN
      limit = category.budget;
      expense = widget.transactions
          .where((t) {
            return t.categoryId == category.id &&
                t.type == 'expense' &&
                t.date.month == now.month &&
                t.date.year == now.year;
          })
          .fold(0, (sum, t) => sum + t.amount);
    }

    final double percentage = limit == 0 ? 0 : expense / limit;
    final int remaining = limit - expense;

    // --- LOGIKA WARNA (Traffic Light) ---
    Color statusColor;
    String statusLabel;

    if (percentage >= 1.0) {
      statusColor = Colors.red;
      statusLabel = "Over";
    } else if (percentage >= 0.75) {
      statusColor = Colors.orange;
      statusLabel = "Waspada";
    } else {
      statusColor = Colors.green;
      statusLabel = "Aman";
    }

    // Progress bar max 1.0
    final double progressValue = percentage > 1.0 ? 1.0 : percentage;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // ICON (Warna Sesuai Kategori)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Color(category.color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.getIcon(category.icon),
                  size: 16,
                  color: Color(category.color), // Warna Icon Tetap Kategori
                ),
              ),
              const SizedBox(width: 8),

              // NAMA & LIMIT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Limit: ${_formatCompact(limit)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // LABEL STATUS (Warna Traffic Light)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor, // Warna Label Berubah
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // PROGRESS BAR (Warna Traffic Light) & SISA
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    color: statusColor, // Warna Bar Berubah
                    backgroundColor: Colors.grey[200],
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                remaining < 0
                    ? "-${_formatCompact(remaining.abs())}"
                    : _formatCompact(remaining),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: remaining < 0 ? Colors.red : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(
          'Belum ada kategori\ndengan budget',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ),
    );
  }

  String _formatCompact(int number) {
    final formatter = NumberFormat.compact(locale: 'id_ID');
    return formatter.format(number);
  }
}
