import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final int? id; // Nullable karena saat create baru, ID belum ada (auto-inc)
  final String name;
  final String icon; // Kita simpan nama icon (misal: 'fastfood')
  final int color; // Kita simpan integer warna (0xFF...)
  final String type; // 'income' atau 'expense'

  const Category({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'icon': icon, 'color': color, 'type': type};
  }

  // Helper factory untuk membuat object dari Map (dari Database)
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: map['color'],
      type: map['type'],
    );
  }

  @override
  List<Object?> get props => [id, name, icon, color, type];
}
