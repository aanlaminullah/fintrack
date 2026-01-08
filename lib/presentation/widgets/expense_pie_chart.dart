import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../providers/chart_provider.dart';

class ExpensePieChart extends ConsumerWidget {
  const ExpensePieChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartDataAsync = ref.watch(expenseByCategoryProvider);

    return chartDataAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return const SizedBox.shrink(); // Jangan tampilkan apa-apa jika belum ada data
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              const Text(
                'Pengeluaran per Kategori',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  children: [
                    // BAGIAN KIRI: Pie Chart
                    Expanded(
                      flex: 6, // Mengambil 60% lebar
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2, // Jarak antar irisan
                          centerSpaceRadius: 40, // Bolong di tengah (Donut)
                          sections: _generateSections(data),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // BAGIAN KANAN: Keterangan (Legend)
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _generateLegend(data),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error: $e'),
    );
  }

  // Helper: Mengubah data Map menjadi Bagian Chart (Sections)
  List<PieChartSectionData> _generateSections(Map<String, int> data) {
    final total = data.values.fold(0, (sum, item) => sum + item);

    return data.entries.map((entry) {
      final splitKey = entry.key.split('|'); // Pisahkan "Nama|Warna"
      // final name = splitKey[0];
      final colorInt = int.tryParse(splitKey[1]) ?? 0xFF9E9E9E;
      final value = entry.value;
      final percentage = (value / total * 100).toStringAsFixed(0);

      return PieChartSectionData(
        color: Color(colorInt),
        value: value.toDouble(),
        title: '$percentage%', // Tampilkan persentase di dalam chart
        radius: 40, // Ketebalan donut
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  // Helper: Membuat Legend (Daftar nama kategori di sebelah kanan)
  List<Widget> _generateLegend(Map<String, int> data) {
    // Ambil maksimal 4 kategori saja agar tidak overflow
    final limitedData = data.entries.take(4).toList();

    return limitedData.map((entry) {
      final splitKey = entry.key.split('|');
      final name = splitKey[0];
      final colorInt = int.tryParse(splitKey[1]) ?? 0xFF9E9E9E;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Color(colorInt),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
