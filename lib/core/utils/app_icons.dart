import 'package:flutter/material.dart';

class AppIcons {
  // Peta (Map) lengkap String -> IconData
  static final Map<String, IconData> map = {
    'fastfood': Icons.fastfood,
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'directions_car': Icons.directions_car,
    'commute': Icons.commute,
    'flight': Icons.flight,
    'shopping_cart': Icons.shopping_cart,
    'shopping_bag': Icons.shopping_bag,
    'movie': Icons.movie,
    'sports_esports': Icons.sports_esports,
    'fitness_center': Icons.fitness_center,
    'health_and_safety': Icons.health_and_safety,
    'school': Icons.school,
    'book': Icons.book,
    'work': Icons.work,
    'attach_money': Icons.attach_money,
    'savings': Icons.savings,
    'home': Icons.home,
    'build': Icons.build,
    'pets': Icons.pets,
    'child_care': Icons.child_care,
    'card_giftcard': Icons.card_giftcard,
    'wifi': Icons.wifi,
    'phone_android': Icons.phone_android,
    // Tambahkan icon lain di sini jika butuh
  };

  // Helper untuk mendapatkan IconData dari String
  static IconData getIcon(String iconName) {
    // Jika iconName ada di map, kembalikan icon-nya
    // Jika tidak ada, kembalikan icon default (category)
    return map[iconName] ?? Icons.category;
  }
}
