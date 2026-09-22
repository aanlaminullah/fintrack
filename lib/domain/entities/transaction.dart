import 'package:equatable/equatable.dart';
import 'category.dart';
import 'funding_source.dart';

class Transaction extends Equatable {
  final int? id;
  final String title;
  final int amount;
  final String type; // 'income' atau 'expense'
  final int categoryId;
  final DateTime date;
  final String? note;
  final int? fundingSourceId;

  // Field ini opsional, diisi jika kita melakukan query JOIN table
  final Category? category;
  final FundingSource? fundingSource;

  const Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note,
    required this.fundingSourceId,
    this.category,
    this.fundingSource,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    type,
    categoryId,
    date,
    note,
    fundingSourceId,
    category,
    fundingSource,
  ];
}
