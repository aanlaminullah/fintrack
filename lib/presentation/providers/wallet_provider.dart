import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../domain/entities/wallet.dart';

// 1. Provider List Semua Wallet
final walletListProvider = FutureProvider<List<Wallet>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final result = await db.query('wallets');
  return result.map((json) => Wallet.fromMap(json)).toList();
});

// 2. Provider Wallet yang SEDANG DIPILIH (State)
class SelectedWalletNotifier extends Notifier<Wallet?> {
  @override
  Wallet? build() {
    return null;
  }

  // Load wallet pertama kali (Default ke ID 1 atau yang pertama ketemu)
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

  // --- PERBAIKAN DI SINI: Auto-Generate Kategori Default ---
  Future<void> addWallet(String name, bool isMonthly) async {
    final db = await DatabaseHelper.instance.database;

    // 1. Buat Wallet Baru
    int newWalletId = await db.insert('wallets', {
      'name': name,
      'is_monthly': isMonthly ? 1 : 0,
    });

    // 2. Siapkan Kategori Default untuk Wallet ini
    final List<Map<String, dynamic>> defaultCategories = [
      // PENGELUARAN
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

      // PEMASUKAN
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
      {
        'name': 'Bonus',
        'icon': 'card_giftcard',
        'color': 0xFFBA68C8,
        'type': 'income',
        'budget': 0,
        'is_weekly': 0,
        'wallet_id': newWalletId,
      },
    ];

    // 3. Masukkan Kategori ke Database
    for (var cat in defaultCategories) {
      await db.insert('categories', cat);
    }

    // 4. Otomatis pilih wallet baru tersebut (Opsional)
    final newWallet = Wallet(id: newWalletId, name: name, isMonthly: isMonthly);
    state = newWallet;
  }
}

final selectedWalletProvider =
    NotifierProvider<SelectedWalletNotifier, Wallet?>(
      SelectedWalletNotifier.new,
    );
