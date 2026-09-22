import 'package:equatable/equatable.dart';
import 'funding_source.dart';

class FundingSourceTransfer extends Equatable {
  final int? id;
  final int fromSourceId;
  final int toSourceId;
  final int amount;
  final DateTime date;
  final String? note;

  // Diisi jika query JOIN, untuk tampilan
  final FundingSource? fromSource;
  final FundingSource? toSource;

  const FundingSourceTransfer({
    this.id,
    required this.fromSourceId,
    required this.toSourceId,
    required this.amount,
    required this.date,
    this.note,
    this.fromSource,
    this.toSource,
  });

  @override
  List<Object?> get props => [
    id,
    fromSourceId,
    toSourceId,
    amount,
    date,
    note,
    fromSource,
    toSource,
  ];
}
