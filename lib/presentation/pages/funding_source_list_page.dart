import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/currency_formatter.dart';
import '../providers/funding_source_provider.dart';
import 'funding_source_form_page.dart';
import 'funding_source_detail_page.dart';

class FundingSourceListPage extends ConsumerWidget {
  const FundingSourceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fundingSourceListAsync = ref.watch(fundingSourceListProvider);
    final balancesAsync = ref.watch(fundingSourceBalancesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Sumber Dana')),
      body: fundingSourceListAsync.when(
        data: (fundingSources) {
          if (fundingSources.isEmpty) {
            return const Center(child: Text('Belum ada sumber dana'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: fundingSources.length,
            itemBuilder: (context, index) {
              final fundingSource = fundingSources[index];
              final balance = balancesAsync.maybeWhen(
                data: (balances) =>
                    balances[fundingSource.id] ?? fundingSource.initialBalance,
                orElse: () => fundingSource.initialBalance,
              );

              return Dismissible(
                key: Key('funding_source_${fundingSource.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus Sumber Dana?'),
                      content: Text(
                        'Hapus "${fundingSource.name}"? Sumber dana yang masih dipakai di transaksi tidak bisa dihapus.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Hapus',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  try {
                    await ref
                        .read(fundingSourceListProvider.notifier)
                        .deleteFundingSource(fundingSource.id!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${fundingSource.name} dihapus'),
                        ),
                      );
                    }
                  } catch (e) {
                    ref.invalidate(fundingSourceListProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.teal,
                      ),
                    ),
                    title: Text(
                      fundingSource.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Saldo: ${formatRupiah(balance)}'),
                        if (!fundingSource.isActive)
                          const Text(
                            'Status: Tidak Aktif',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                      ],
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FundingSourceDetailPage(
                            fundingSource: fundingSource,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FundingSourceFormPage()),
          );
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
