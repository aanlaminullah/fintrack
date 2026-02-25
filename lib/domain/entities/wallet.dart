import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final int? id;
  final String name;
  final bool
  isMonthly; // true = Reset tiap bulan, false = Akumulasi (Project/Tabungan)

  const Wallet({
    this.id,
    required this.name,
    this.isMonthly = true, // Default Bulanan
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'is_monthly': isMonthly ? 1 : 0};
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'],
      name: map['name'],
      isMonthly: (map['is_monthly'] ?? 1) == 1,
    );
  }

  @override
  List<Object?> get props => [id, name, isMonthly];
}
