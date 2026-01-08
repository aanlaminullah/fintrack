import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_icons.dart';
import '../../domain/entities/category.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart'; // Import ini untuk refresh transaksi
import '../providers/usecase_providers.dart'; // Import ini untuk delete logic
import 'category_form_page.dart';

class CategoryListPage extends ConsumerWidget {
  const CategoryListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ambil data kategori dari provider
    final categoryListAsync = ref.watch(categoryListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kategori')),
      body: categoryListAsync.when(
        data: (categories) {
          // Pisahkan kategori berdasarkan tipe
          final expenseCategories = categories
              .where((c) => c.type == 'expense')
              .toList();
          final incomeCategories = categories
              .where((c) => c.type == 'income')
              .toList();

          return ListView(
            children: [
              // 1. HEADER PENGELUARAN
              _buildSectionHeader('Pengeluaran', Colors.red),

              // 2. LIST ITEM PENGELUARAN (Dengan Dismissible)
              ...expenseCategories.map(
                (category) => _buildCategoryItem(context, ref, category),
              ),

              const Divider(height: 32),

              // 3. HEADER PEMASUKAN
              _buildSectionHeader('Pemasukan', Colors.green),

              // 4. LIST ITEM PEMASUKAN (Dengan Dismissible)
              ...incomeCategories.map(
                (category) => _buildCategoryItem(context, ref, category),
              ),

              // Tambahan padding bawah agar tidak tertutup FAB
              const SizedBox(height: 80),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Buka Form Tambah (Tanpa parameter edit)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CategoryFormPage()),
          );
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Helper Widget untuk Header
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  // Helper Widget untuk Item Kategori (Edit & Delete Logic ada di sini)
  Widget _buildCategoryItem(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) {
    return Dismissible(
      key: Key('cat_${category.id}'), // Key unik wajib ada
      direction: DismissDirection.endToStart, // Geser kanan ke kiri
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        // Dialog Konfirmasi Hapus
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hapus Kategori?'),
            content: Text('Kategori "${category.name}" akan dihapus permanen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        // 1. Panggil UseCase Delete
        final deleteUseCase = ref.read(deleteCategoryProvider);
        await deleteUseCase(category.id!);

        // 2. Refresh Provider Kategori & Transaksi (agar UI sinkron)
        ref.invalidate(categoryListProvider);
        ref.invalidate(transactionListProvider);

        // 3. Feedback Snackbar
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${category.name} dihapus')));
      },
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(category.color).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            AppIcons.getIcon(category.icon), // Menggunakan AppIcons yang benar
            color: Color(category.color),
          ),
        ),
        title: Text(category.name),
        // trailing: const Icon(Icons.edit, size: 18, color: Colors.grey),
        onTap: () {
          // Navigasi ke Form Edit (Bawa data kategori lama)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryFormPage(categoryToEdit: category),
            ),
          );
        },
      ),
    );
  }
}
