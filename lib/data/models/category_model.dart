import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    super.id,
    required super.name,
    required super.icon,
    required super.color,
    required super.type,
    super.budget = 0,
    super.isWeekly = false, // <--- Tambahan
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: json['color'],
      type: json['type'],
      budget: json['budget'] ?? 0,
      isWeekly: (json['is_weekly'] ?? 0) == 1, // <--- Baca kolom database
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'budget': budget,
      'is_weekly': isWeekly ? 1 : 0, // <--- Tulis ke database
    };
  }
}
