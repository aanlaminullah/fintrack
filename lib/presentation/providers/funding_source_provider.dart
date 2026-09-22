import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../domain/entities/funding_source.dart';
import 'transaction_provider.dart';

// 1. Provider List Semua Sumber Dana
final fundingSourceListProvider =
    AsyncNotifierProvider<FundingSourceListNotifier, List<FundingSource>>(() {
      return FundingSourceListNotifier();
    });

class FundingSourceListNotifier extends AsyncNotifier<List<FundingSource>> {
  @override
  Future<List<FundingSource>> build() async {
    return _fetchFundingSources();
  }

  Future<List<FundingSource>> _fetchFundingSources() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('funding_sources');
    return result.map((json) => FundingSource.fromMap(json)).toList();
  }

  Future<void> addFundingSource(String name, int initialBalance) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('funding_sources', {
      'name': name,
      'initial_balance': initialBalance,
      'is_active': 1,
    });
    state = AsyncValue.data(await _fetchFundingSources());
    ref.invalidate(fundingSourceBalancesProvider);
  }

  Future<void> updateFundingSource(FundingSource fundingSource) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'funding_sources',
      fundingSource.toMap(),
      where: 'id = ?',
      whereArgs: [fundingSource.id],
    );
    state = AsyncValue.data(await _fetchFundingSources());
    ref.invalidate(fundingSourceBalancesProvider);
  }

  Future<void> deleteFundingSource(int id) async {
    final db = await DatabaseHelper.instance.database;
    try {
      await db.delete('funding_sources', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      throw Exception(
        'Sumber dana masih dipakai di transaksi, tidak bisa dihapus',
      );
    }
    state = AsyncValue.data(await _fetchFundingSources());
    ref.invalidate(fundingSourceBalancesProvider);
  }
}

// 2. Provider Saldo Berjalan Tiap Sumber Dana
// Hitung: saldo_awal + income - expense - transfer_keluar + transfer_masuk
final fundingSourceBalancesProvider = FutureProvider<Map<int, int>>((
  ref,
) async {
  // Ikut refresh saat ada transaksi baru atau funding source berubah
  ref.watch(fundingSourceListProvider);
  ref.watch(transactionListProvider);

  final db = await DatabaseHelper.instance.database;
  final result = await db.rawQuery('''
    SELECT
      fs.id,
      fs.initial_balance
        + COALESCE((SELECT SUM(amount) FROM transactions WHERE funding_source_id = fs.id AND type = 'income'), 0)
        - COALESCE((SELECT SUM(amount) FROM transactions WHERE funding_source_id = fs.id AND type = 'expense'), 0)
        - COALESCE((SELECT SUM(amount) FROM funding_source_transfers WHERE from_source_id = fs.id), 0)
        + COALESCE((SELECT SUM(amount) FROM funding_source_transfers WHERE to_source_id = fs.id), 0)
        AS current_balance
    FROM funding_sources fs
  ''');

  final Map<int, int> balances = {};
  for (var row in result) {
    balances[row['id'] as int] = (row['current_balance'] as int?) ?? 0;
  }
  return balances;
});

// 3. Provider Sumber Dana yang SEDANG DIPILIH di form transaksi (state sementara)
class SelectedFundingSourceNotifier extends Notifier<FundingSource?> {
  @override
  FundingSource? build() {
    return null;
  }

  void selectFundingSource(FundingSource? fundingSource) {
    state = fundingSource;
  }
}

final selectedFundingSourceProvider =
    NotifierProvider<SelectedFundingSourceNotifier, FundingSource?>(
      SelectedFundingSourceNotifier.new,
    );

// 4. Model ringan untuk 1 baris riwayat (transaksi ATAU transfer)
class FundingSourceHistoryItem {
  final DateTime date;
  final String title;
  final String subtitle;
  final int amount; // signed: + = uang masuk, - = uang keluar
  final String kind; // 'income' | 'expense' | 'transfer_in' | 'transfer_out'

  FundingSourceHistoryItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.kind,
  });
}

// 5. Provider Riwayat Gabungan per Sumber Dana (transaksi + transfer)
final fundingSourceHistoryProvider =
    FutureProvider.family<List<FundingSourceHistoryItem>, int>((
      ref,
      sourceId,
    ) async {
      ref.watch(
        fundingSourceBalancesProvider,
      ); // auto refresh saat ada perubahan

      final db = await DatabaseHelper.instance.database;

      // a. Transaksi income/expense dari sumber dana ini
      final txResult = await db.rawQuery(
        '''
    SELECT t.title, t.amount, t.type, t.date, c.name as category_name
    FROM transactions t
    LEFT JOIN categories c ON t.category_id = c.id
    WHERE t.funding_source_id = ?
    ''',
        [sourceId],
      );

      final txItems = txResult.map((row) {
        final isExpense = row['type'] == 'expense';
        final amount = row['amount'] as int;
        return FundingSourceHistoryItem(
          date: DateTime.parse(row['date'] as String),
          title: row['title'] as String,
          subtitle: (row['category_name'] as String?) ?? 'Umum',
          amount: isExpense ? -amount : amount,
          kind: isExpense ? 'expense' : 'income',
        );
      });

      // b. Transfer KELUAR dari sumber dana ini
      final outResult = await db.rawQuery(
        '''
    SELECT tr.amount, tr.date, tr.note, fs.name as to_name
    FROM funding_source_transfers tr
    LEFT JOIN funding_sources fs ON tr.to_source_id = fs.id
    WHERE tr.from_source_id = ?
    ''',
        [sourceId],
      );

      final outItems = outResult.map((row) {
        return FundingSourceHistoryItem(
          date: DateTime.parse(row['date'] as String),
          title: 'Transfer ke ${row['to_name'] ?? '-'}',
          subtitle: (row['note'] as String?) ?? 'Transfer keluar',
          amount: -(row['amount'] as int),
          kind: 'transfer_out',
        );
      });

      // c. Transfer MASUK ke sumber dana ini
      final inResult = await db.rawQuery(
        '''
    SELECT tr.amount, tr.date, tr.note, fs.name as from_name
    FROM funding_source_transfers tr
    LEFT JOIN funding_sources fs ON tr.from_source_id = fs.id
    WHERE tr.to_source_id = ?
    ''',
        [sourceId],
      );

      final inItems = inResult.map((row) {
        return FundingSourceHistoryItem(
          date: DateTime.parse(row['date'] as String),
          title: 'Transfer dari ${row['from_name'] ?? '-'}',
          subtitle: (row['note'] as String?) ?? 'Transfer masuk',
          amount: row['amount'] as int,
          kind: 'transfer_in',
        );
      });

      final all = [...txItems, ...outItems, ...inItems];
      all.sort((a, b) => b.date.compareTo(a.date));
      return all;
    });
