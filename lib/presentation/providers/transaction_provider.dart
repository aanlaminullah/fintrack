import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../domain/entities/transaction.dart';
import '../../data/models/transaction_model.dart';
import 'wallet_provider.dart';
import 'usecase_providers.dart'; // Import usecase untuk dashboard summary (opsional jika dipakai di logic lain)

// --- 1. PROVIDER LIST TRANSAKSI UTAMA ---
final transactionListProvider =
    AsyncNotifierProvider<TransactionList, List<Transaction>>(() {
      return TransactionList();
    });

class TransactionList extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    // 1. Dengarkan perubahan pada Wallet yang dipilih
    final currentWallet = ref.watch(selectedWalletProvider);

    // 2. Jika belum ada wallet yang dipilih, kembalikan list kosong
    if (currentWallet == null) return [];

    // 3. Ambil transaksi milik wallet tersebut
    return _fetchTransactions(currentWallet.id!);
  }

  Future<List<Transaction>> _fetchTransactions(int walletId) async {
    final db = await DatabaseHelper.instance.database;

    // PERBAIKAN: Menggunakan rawQuery dengan LEFT JOIN agar Icon & Warna Kategori MUNCUL
    final result = await db.rawQuery(
      '''
      SELECT t.id, t.title, t.amount, t.date, t.type, t.category_id, t.note, t.wallet_id,
             c.name as category_name, c.icon as category_icon, c.color as category_color, c.type as category_type
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.wallet_id = ?
      ORDER BY t.date DESC
    ''',
      [walletId],
    );

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<void> addTransaction(Transaction transaction) async {
    final currentWallet = ref.read(selectedWalletProvider);
    if (currentWallet == null) return;

    final db = await DatabaseHelper.instance.database;

    final transactionModel = TransactionModel(
      id: transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      date: transaction.date,
      note: transaction.note,
    );

    final Map<String, dynamic> data = transactionModel.toJson();
    data['wallet_id'] = currentWallet.id; // Set pemilik wallet

    await db.insert('transactions', data);

    // Refresh state
    state = AsyncValue.data(await _fetchTransactions(currentWallet.id!));

    // Refresh summary dashboard juga
    ref.invalidate(dashboardSummaryProvider);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final currentWallet = ref.read(selectedWalletProvider);
    if (currentWallet == null) return;

    final db = await DatabaseHelper.instance.database;

    final transactionModel = TransactionModel(
      id: transaction.id,
      title: transaction.title,
      amount: transaction.amount,
      type: transaction.type,
      categoryId: transaction.categoryId,
      date: transaction.date,
      note: transaction.note,
    );

    final Map<String, dynamic> data = transactionModel.toJson();
    data['wallet_id'] = currentWallet.id;

    await db.update(
      'transactions',
      data,
      where: 'id = ?',
      whereArgs: [transaction.id],
    );

    state = AsyncValue.data(await _fetchTransactions(currentWallet.id!));
    ref.invalidate(dashboardSummaryProvider);
  }

  Future<void> deleteTransaction(int id) async {
    final currentWallet = ref.read(selectedWalletProvider);
    if (currentWallet == null) return;

    final db = await DatabaseHelper.instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);

    state = AsyncValue.data(await _fetchTransactions(currentWallet.id!));
    ref.invalidate(dashboardSummaryProvider);
  }
}

// --- 2. PROVIDER SUMMARY (Hitung Total Saldo/Pemasukan/Pengeluaran) ---
final dashboardSummaryProvider =
    Provider.autoDispose<AsyncValue<Map<String, int>>>((ref) {
      final transactionsAsync = ref.watch(transactionListProvider);
      final currentWallet = ref.watch(selectedWalletProvider);

      return transactionsAsync.whenData((transactions) {
        final isMonthlyWallet = currentWallet?.isMonthly ?? true;

        int totalIncome = 0;
        int totalExpense = 0;
        int monthlyIncome = 0;
        int monthlyExpense = 0;

        final now = DateTime.now();

        for (var t in transactions) {
          if (t.type == 'income') totalIncome += t.amount;
          if (t.type == 'expense') totalExpense += t.amount;

          DateTime tDate;
          try {
            tDate = t.date;
          } catch (_) {
            tDate = DateTime.parse(t.date.toString());
          }

          if (tDate.year == now.year && tDate.month == now.month) {
            if (t.type == 'income') monthlyIncome += t.amount;
            if (t.type == 'expense') monthlyExpense += t.amount;
          }
        }

        return {
          // Jika bulanan, tampilkan data bulan ini. Jika akumulasi, tampilkan all-time.
          'income': isMonthlyWallet ? monthlyIncome : totalIncome,
          'expense': isMonthlyWallet ? monthlyExpense : totalExpense,
          'total': totalIncome - totalExpense,
        };
      });
    });
