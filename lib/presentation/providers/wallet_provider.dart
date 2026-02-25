import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../domain/entities/wallet.dart';
import 'transaction_provider.dart';
import 'category_provider.dart';

// 1. Provider List Semua Wallet (Sekarang menggunakan AsyncNotifier agar bisa CRUD)
final walletListProvider =
    AsyncNotifierProvider<WalletListNotifier, List<Wallet>>(() {
      return WalletListNotifier();
    });

class WalletListNotifier extends AsyncNotifier<List<Wallet>> {
  @override
  Future<List<Wallet>> build() async {
    return _fetchWallets();
  }

  Future<List<Wallet>> _fetchWallets() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('wallets');
    return result.map((json) => Wallet.fromMap(json)).toList();
  }

  Future<void> addWallet(String name, bool isMonthly) async {
    final db = await DatabaseHelper.instance.database;

    // 1. Buat Wallet Baru
    int newWalletId = await db.insert('wallets', {
      'name': name,
      'is_monthly': isMonthly ? 1 : 0,
    });

    // 2. Siapkan Kategori Default untuk Wallet ini
    final List<Map<String, dynamic>> defaultCategories = [
      {
        'name': 'Makan',
        'icon': 'fastfood',
        'color': 0xFFE57373,
        'type': 'expense',
        'budget': 0,
        'is_weekly': 0,
        'wallet_id': newWalletId,
      },
      {
        'name': 'Transport',
        'icon': 'directions_car',
        'color': 0xFF64B5F6,
        'type': 'expense',
        'budget': 0,
        'is_weekly': 0,
        'wallet_id': newWalletId,
      },
      {
        'name': 'Belanja',
        'icon': 'shopping_cart',
        'color': 0xFFFFD54F,
        'type': 'expense',
        'budget': 0,
        'is_weekly': 0,
        'wallet_id': newWalletId,
      },
      {
        'name': 'Hiburan',
        'icon': 'movie',
        'color': 0xFFBA68C8,
        'type': 'expense',
        'budget': 0,
        'is_weekly': 0,
        'wallet_id': newWalletId,
      },
      {
        'name': 'Tagihan',
        'icon': 'receipt',
        'color': 0xFFFF8A65,
        'type': 'expense',
        'budget': 0,
        'is_weekly': 0,
        'wallet_id': newWalletId,
      },
      {
        'name': 'Gaji',
        'icon': 'attach_money',
        'color': 0xFF81C784,
        'type': 'income',
        'budget': 0,
        'is_weekly': 0,
        'wallet_id': newWalletId,
      },
      {
        'name': 'Freelance',
        'icon': 'computer',
        'color': 0xFF4DB6AC,
        'type': 'income',
        'budget': 0,
        'is_weekly': 0,
        'wallet_id': newWalletId,
      },
    ];

    for (var cat in defaultCategories) {
      await db.insert('categories', cat);
    }

    // Refresh list wallet
    state = AsyncValue.data(await _fetchWallets());
  }

  Future<void> updateWallet(Wallet wallet) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );

    // Update state selected wallet jika yang diedit adalah yang sedang aktif
    final currentSelected = ref.read(selectedWalletProvider);
    if (currentSelected?.id == wallet.id) {
      ref.read(selectedWalletProvider.notifier).selectWallet(wallet);
    }

    state = AsyncValue.data(await _fetchWallets());
  }

  Future<void> deleteWallet(int id) async {
    final db = await DatabaseHelper.instance.database;
    // Berkat ON DELETE CASCADE di database_helper, kategori dan transaksi terkait akan otomatis terhapus
    await db.delete('wallets', where: 'id = ?', whereArgs: [id]);

    final updatedWallets = await _fetchWallets();
    state = AsyncValue.data(updatedWallets);

    // Jika wallet yang dihapus adalah wallet yang sedang aktif, pindah ke wallet pertama
    final currentSelected = ref.read(selectedWalletProvider);
    if (currentSelected?.id == id && updatedWallets.isNotEmpty) {
      ref
          .read(selectedWalletProvider.notifier)
          .selectWallet(updatedWallets.first);
      ref.invalidate(transactionListProvider);
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(categoryListProvider);
    }
  }
}

// 2. Provider Wallet yang SEDANG DIPILIH (State)
class SelectedWalletNotifier extends Notifier<Wallet?> {
  @override
  Wallet? build() {
    return null;
  }

  Future<void> loadInitial() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('wallets');
    if (result.isNotEmpty) {
      state = Wallet.fromMap(result.first);
    }
  }

  void selectWallet(Wallet wallet) {
    state = wallet;
  }
}

final selectedWalletProvider =
    NotifierProvider<SelectedWalletNotifier, Wallet?>(
      SelectedWalletNotifier.new,
    );
