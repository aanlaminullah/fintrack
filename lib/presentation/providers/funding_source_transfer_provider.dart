import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../domain/entities/funding_source.dart';
import '../../domain/entities/funding_source_transfer.dart';
import 'funding_source_provider.dart';

final fundingSourceTransferListProvider =
    AsyncNotifierProvider<
      FundingSourceTransferListNotifier,
      List<FundingSourceTransfer>
    >(() {
      return FundingSourceTransferListNotifier();
    });

class FundingSourceTransferListNotifier
    extends AsyncNotifier<List<FundingSourceTransfer>> {
  @override
  Future<List<FundingSourceTransfer>> build() async {
    return _fetchTransfers();
  }

  Future<List<FundingSourceTransfer>> _fetchTransfers() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT tr.id, tr.from_source_id, tr.to_source_id, tr.amount, tr.date, tr.note,
             fs_from.name as from_name, fs_to.name as to_name
      FROM funding_source_transfers tr
      LEFT JOIN funding_sources fs_from ON tr.from_source_id = fs_from.id
      LEFT JOIN funding_sources fs_to ON tr.to_source_id = fs_to.id
      ORDER BY tr.date DESC, tr.id DESC
    ''');

    return result.map((row) {
      return FundingSourceTransfer(
        id: row['id'] as int,
        fromSourceId: row['from_source_id'] as int,
        toSourceId: row['to_source_id'] as int,
        amount: row['amount'] as int,
        date: DateTime.parse(row['date'] as String),
        note: row['note'] as String?,
        fromSource: row['from_name'] != null
            ? FundingSource(
                id: row['from_source_id'] as int,
                name: row['from_name'] as String,
              )
            : null,
        toSource: row['to_name'] != null
            ? FundingSource(
                id: row['to_source_id'] as int,
                name: row['to_name'] as String,
              )
            : null,
      );
    }).toList();
  }

  Future<void> addTransfer({
    required int fromSourceId,
    required int toSourceId,
    required int amount,
    required DateTime date,
    String? note,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('funding_source_transfers', {
      'from_source_id': fromSourceId,
      'to_source_id': toSourceId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    });

    state = AsyncValue.data(await _fetchTransfers());
    ref.invalidate(fundingSourceBalancesProvider);
  }

  Future<void> deleteTransfer(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'funding_source_transfers',
      where: 'id = ?',
      whereArgs: [id],
    );
    state = AsyncValue.data(await _fetchTransfers());
    ref.invalidate(fundingSourceBalancesProvider);
  }
}
