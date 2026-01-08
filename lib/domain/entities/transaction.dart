import 'package:equatable/equatable.dart';
import 'category.dart';

class Transaction extends Equatable {
  final int? id;
  final String title;
  final int amount;
  final String type; // 'income' atau 'expense'
  final int categoryId;
  final DateTime date;
  final String? note;

  // Field ini opsional, diisi jika kita melakukan query JOIN table
  final Category? category;

  const Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note,
    this.category,
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
    category,
  ];
}
