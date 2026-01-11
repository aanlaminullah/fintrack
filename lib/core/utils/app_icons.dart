import 'package:flutter/material.dart';

class AppIcons {
  // Peta (Map) icon bawaan (Legacy/Lama)
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
    'category': Icons.category, // Default
  };

  // Helper Cerdas: Bisa baca Nama ("fastfood") ATAU Angka ID ("58941")
  static IconData getIcon(String iconNameOrCode) {
    // 1. Cek apakah string ini adalah Nama Manual yang ada di Map
    if (map.containsKey(iconNameOrCode)) {
      return map[iconNameOrCode]!;
    }

    // 2. Jika tidak ada di Map, coba cek apakah ini Angka (CodePoint dari Picker)
    final codePoint = int.tryParse(iconNameOrCode);
    if (codePoint != null) {
      // Rekonstruksi Icon dari ID Angka
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    }

    // 3. Fallback jika gagal semua
    return Icons.category;
  }
}
