import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final int? id;
  final String name;
  final String icon;
  final int color;
  final String type; // 'income' atau 'expense'
  final int budget;
  final bool isWeekly; // <--- KOLOM BARU: Status Tampilan Mingguan

  const Category({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.budget = 0,
    this.isWeekly = false, // <--- Default False (Bulanan)
  });

  // Convert object ke Map (untuk Database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'budget': budget,
      'is_weekly': isWeekly ? 1 : 0, // Simpan sebagai 1 atau 0
    };
  }

  // Convert Map dari Database ke Object
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      color: map['color'],
      type: map['type'],
      budget: map['budget'] ?? 0,
      isWeekly: (map['is_weekly'] ?? 0) == 1, // Baca 1 sebagai true
    );
  }

  // Fitur CopyWith (PENTING untuk update data nanti)
  Category copyWith({
    int? id,
    String? name,
    String? icon,
    int? color,
    String? type,
    int? budget,
    bool? isWeekly,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      budget: budget ?? this.budget,
      isWeekly: isWeekly ?? this.isWeekly,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, color, type, budget, isWeekly];
}
