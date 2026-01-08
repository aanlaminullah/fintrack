import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';

class SummaryCard extends StatelessWidget {
  final int totalBalance;
  final int income;
  final int expense;

  const SummaryCard({
    super.key,
    required this.totalBalance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24), // Padding agak diperbesar
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF009688), Color(0xFF004D40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF009688).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BAGIAN ATAS: Judul dan Saldo Utama
          const Text(
            'Total Saldo',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),

          // Menggunakan Expanded/Flexible agar font bisa menyesuaikan
          Expanded(
            child: Align(
              alignment: Alignment
                  .centerLeft, // Saldo tetap di kiri tapi vertikal center di area atas
              child: Text(
                formatRupiah(totalBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34, // Font diperbesar
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // BAGIAN BAWAH: Income & Expense (Pemasukan/Pengeluaran)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIndicator(
                  icon: Icons.arrow_downward,
                  color: Colors.greenAccent,
                  label: 'Pemasukan',
                  amount: income,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white24,
                ), // Garis pemisah
                _buildIndicator(
                  icon: Icons.arrow_upward,
                  color: Colors.redAccent,
                  label: 'Pengeluaran',
                  amount: expense,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({
    required IconData icon,
    required Color color,
    required String label,
    required int amount,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              formatRupiah(amount),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
