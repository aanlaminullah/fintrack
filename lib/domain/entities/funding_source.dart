import 'package:equatable/equatable.dart';

class FundingSource extends Equatable {
  final int? id;
  final String name;
  final int initialBalance;
  final bool isActive;

  const FundingSource({
    this.id,
    required this.name,
    this.initialBalance = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'initial_balance': initialBalance,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory FundingSource.fromMap(Map<String, dynamic> map) {
    return FundingSource(
      id: map['id'],
      name: map['name'],
      initialBalance: map['initial_balance'] ?? 0,
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  FundingSource copyWith({
    int? id,
    String? name,
    int? initialBalance,
    bool? isActive,
  }) {
    return FundingSource(
      id: id ?? this.id,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, name, initialBalance, isActive];
}
