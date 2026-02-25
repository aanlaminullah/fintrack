import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wallet.dart';
import '../providers/wallet_provider.dart';
import 'wallet_form_page.dart';

class WalletListPage extends ConsumerWidget {
  const WalletListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletListAsync = ref.watch(walletListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Akun (Wallet)')),
      body: walletListAsync.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return const Center(child: Text("Tidak ada akun"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              final isLastWallet = wallets.length == 1;

              return Dismissible(
                key: Key('wallet_${wallet.id}'),
                direction: isLastWallet
                    ? DismissDirection.none
                    : DismissDirection.endToStart,
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
                      title: const Text('Hapus Akun?'),
                      content: Text(
                        'PERINGATAN: Menghapus akun "${wallet.name}" akan menghapus SEMUA kategori dan transaksi di dalamnya secara permanen.\n\nLanjutkan?',
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
                  await ref
                      .read(walletListProvider.notifier)
                      .deleteWallet(wallet.id!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Akun ${wallet.name} dihapus')),
                  );
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
                      child: Icon(
                        wallet.isMonthly
                            ? Icons.account_balance_wallet
                            : Icons.savings,
                        color: Colors.teal,
                      ),
                    ),
                    title: Text(
                      wallet.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      wallet.isMonthly
                          ? 'Mode Bulanan (Reset)'
                          : 'Mode Tabungan (Akumulasi)',
                    ),
                    trailing: const Icon(
                      Icons.edit,
                      size: 20,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WalletFormPage(walletToEdit: wallet),
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
            MaterialPageRoute(builder: (_) => const WalletFormPage()),
          );
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
