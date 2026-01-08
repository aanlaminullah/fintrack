import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    super.id,
    required super.name,
    required super.icon,
    required super.color,
    required super.type,
  });

  // Mengubah Map (dari SQLite) menjadi Object
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      color: json['color'],
      type: json['type'],
    );
  }

  // Mengubah Object menjadi Map (untuk disimpan ke SQLite)
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'icon': icon, 'color': color, 'type': type};
  }
}
