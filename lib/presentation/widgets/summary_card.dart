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
      // UBAH 1: Kurangi padding utama dari 24 ke 20 agar lebih lega
      padding: const EdgeInsets.all(20),
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
          // BAGIAN ATAS: Judul
          const Text(
            'Total Saldo',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ), // Sedikit perkecil font
          ),
          const SizedBox(height: 4), // Kurangi jarak
          // BAGIAN TENGAH: Saldo Utama
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                // Tambahkan FittedBox agar font otomatis mengecil jika kepanjangan/sempit
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatRupiah(totalBalance),
                  style: const TextStyle(
                    color: Colors.white,
                    // UBAH 2: Kurangi ukuran font saldo dari 34 ke 30 agar tidak overflow
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // BAGIAN BAWAH: Income & Expense
          Container(
            // UBAH 3: Kurangi padding vertikal kontainer bawah
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Pemasukan
                Expanded(
                  child: _buildIndicator(
                    icon: Icons.arrow_downward,
                    color: Colors.greenAccent,
                    label: 'Pemasukan',
                    amount: income,
                  ),
                ),

                // Garis Pemisah
                Container(
                  width: 1,
                  height: 30, // Sedikit pendekkan garis
                  color: Colors.white24,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),

                // Pengeluaran
                Expanded(
                  child: _buildIndicator(
                    icon: Icons.arrow_upward,
                    color: Colors.redAccent,
                    label: 'Pengeluaran',
                    amount: expense,
                  ),
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
          child: Icon(icon, color: color, size: 16), // Perkecil icon sedikit
        ),
        const SizedBox(width: 8),
        Expanded(
          // Gunakan Expanded agar teks tidak menabrak kanan jika nominal panjang
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
              FittedBox(
                // FittedBox agar nominal panjang tidak error overflow
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatRupiah(amount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
