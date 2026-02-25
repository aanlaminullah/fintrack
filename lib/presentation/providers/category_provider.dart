import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../domain/entities/category.dart';
import '../../data/models/category_model.dart';
import 'wallet_provider.dart';

// Provider Utama
final categoryListProvider =
    AsyncNotifierProvider<CategoryList, List<Category>>(() {
      return CategoryList();
    });

class CategoryList extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    // 1. Dengarkan perubahan Wallet
    final currentWallet = ref.watch(selectedWalletProvider);

    // 2. Safety check
    if (currentWallet == null) return [];

    // 3. Ambil kategori milik wallet tersebut
    return _fetchCategories(currentWallet.id!);
  }

  Future<List<Category>> _fetchCategories(int walletId) async {
    final db = await DatabaseHelper.instance.database;

    // Query dengan Filter Wallet ID
    final result = await db.query(
      'categories',
      where: 'wallet_id = ?',
      whereArgs: [walletId],
      orderBy: 'id ASC',
    );

    return result.map((json) => CategoryModel.fromJson(json)).toList();
  }

  // --- ADD CATEGORY (Dengan Wallet ID) ---
  Future<void> addCategory(Category category) async {
    final currentWallet = ref.read(selectedWalletProvider);
    if (currentWallet == null) return;

    final db = await DatabaseHelper.instance.database;

    final categoryModel = CategoryModel(
      name: category.name,
      icon: category.icon,
      color: category.color,
      type: category.type,
      budget: category.budget,
      isWeekly: category.isWeekly,
    );

    final Map<String, dynamic> data = categoryModel.toJson();
    data['wallet_id'] = currentWallet.id; // <--- PENTING: Inject Wallet ID

    await db.insert('categories', data);

    // Refresh list
    state = AsyncValue.data(await _fetchCategories(currentWallet.id!));
  }

  // --- UPDATE CATEGORY ---
  Future<void> updateCategory(Category category) async {
    final currentWallet = ref.read(selectedWalletProvider);
    if (currentWallet == null) return;

    final db = await DatabaseHelper.instance.database;

    // Kita gunakan toMap() dari entity atau toJson() dari model,
    // tapi pastikan wallet_id tetap terjaga (biasanya update berdasarkan ID tidak ubah wallet_id)
    final categoryModel = CategoryModel(
      id: category.id,
      name: category.name,
      icon: category.icon,
      color: category.color,
      type: category.type,
      budget: category.budget,
      isWeekly: category.isWeekly,
    );

    final Map<String, dynamic> data = categoryModel.toJson();
    data['wallet_id'] = currentWallet.id; // Pastikan tetap di wallet yang sama

    await db.update(
      'categories',
      data,
      where: 'id = ?',
      whereArgs: [category.id],
    );

    // Refresh list
    state = AsyncValue.data(await _fetchCategories(currentWallet.id!));
  }

  // --- DELETE CATEGORY ---
  Future<void> deleteCategory(int id) async {
    final currentWallet = ref.read(selectedWalletProvider);
    if (currentWallet == null) return;

    final db = await DatabaseHelper.instance.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);

    // Refresh list
    state = AsyncValue.data(await _fetchCategories(currentWallet.id!));
  }
}
