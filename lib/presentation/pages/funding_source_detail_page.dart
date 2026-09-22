import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/funding_source.dart';
import '../providers/funding_source_provider.dart';
import 'funding_source_form_page.dart';

class FundingSourceDetailPage extends ConsumerWidget {
  final FundingSource fundingSource;

  const FundingSourceDetailPage({super.key, required this.fundingSource});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(fundingSourceBalancesProvider);
    final historyAsync = ref.watch(
      fundingSourceHistoryProvider(fundingSource.id!),
    );

    final balance = balancesAsync.maybeWhen(
      data: (b) => b[fundingSource.id] ?? fundingSource.initialBalance,
      orElse: () => fundingSource.initialBalance,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(fundingSource.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FundingSourceFormPage(fundingSourceToEdit: fundingSource),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo Saat Ini',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  formatRupiah(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Riwayat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: historyAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('Belum ada riwayat'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isNegative = item.amount < 0;
                    final isTransfer = item.kind.startsWith('transfer');

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(
                          isTransfer
                              ? Icons.swap_horiz
                              : (isNegative
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward),
                          color: isTransfer
                              ? Colors.indigo
                              : (isNegative ? Colors.red : Colors.green),
                        ),
                        title: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${item.subtitle} • ${formatDate(item.date)}',
                        ),
                        trailing: Text(
                          '${isNegative ? '-' : '+'} ${formatRupiah(item.amount.abs())}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isNegative ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
