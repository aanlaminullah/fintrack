import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExpensePieChart extends StatelessWidget {
  // Terima data dari Parent (Dashboard / Analysis Page)
  final AsyncValue<Map<String, int>> chartData;

  const ExpensePieChart({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    return chartData.when(
      data: (data) {
        if (data.isEmpty) {
          // Tampilan jika data bulan ini kosong
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 48,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada pengeluaran\ndi bulan ini',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
            ),
          );
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
                    // Pie Chart
                    Expanded(
                      flex: 6,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: _generateSections(data),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Legend
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
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  // --- Helpers ---
  List<PieChartSectionData> _generateSections(Map<String, int> data) {
    final total = data.values.fold(0, (sum, item) => sum + item);
    return data.entries.map((entry) {
      final splitKey = entry.key.split('|');
      final colorInt = int.tryParse(splitKey[1]) ?? 0xFF9E9E9E;
      final value = entry.value;
      final percentage = (value / total * 100).toStringAsFixed(0);

      return PieChartSectionData(
        color: Color(colorInt),
        value: value.toDouble(),
        title: '$percentage%',
        radius: 40,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _generateLegend(Map<String, int> data) {
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
