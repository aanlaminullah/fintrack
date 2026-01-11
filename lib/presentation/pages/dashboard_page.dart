import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import Providers
import '../providers/transaction_provider.dart';
import '../providers/chart_provider.dart';
import '../providers/category_provider.dart'; // <--- TAMBAHKAN INI

// Import Widgets & Pages
import '../widgets/summary_card.dart';
import '../widgets/transaction_item.dart';
import '../widgets/expense_pie_chart.dart';
import 'add_transaction_page.dart';
import 'category_list_page.dart';
import 'transaction_search_page.dart';
import 'expense_analysis_page.dart';

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/datasources/local/database_helper.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(dashboardSummaryProvider);
    final transactionListState = ref.watch(transactionListProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],

      // --- SIDEBAR MODERN (EndDrawer) ---
      endDrawer: Drawer(
        backgroundColor: Colors.white,
        elevation: 0,
        width: MediaQuery.of(context).size.width * 0.8, // Lebar 80% layar
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            bottomLeft: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER MODERN (Judul & Close Button)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Menu',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. LIST MENU ITEM
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildModernMenuItem(
                      context,
                      title: 'Kelola Kategori',
                      icon: Icons.category_outlined,
                      color: Colors.teal,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CategoryListPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),

                    // MENU EXPORT
                    _buildModernMenuItem(
                      context,
                      title: 'Backup Data (Export)',
                      icon: Icons.upload_file,
                      color: Colors.blue,
                      onTap: _exportData, // Panggil fungsi export
                    ),

                    // MENU IMPORT
                    _buildModernMenuItem(
                      context,
                      title: 'Restore Data (Import)',
                      icon: Icons.download_for_offline,
                      color: Colors.orange,
                      onTap: _importData, // Panggil fungsi import
                    ),

                    // Contoh Menu Lain (Disabled / Coming Soon)
                    /*
                    const SizedBox(height: 10),
                    _buildModernMenuItem(
                      context,
                      title: 'Pengaturan',
                      icon: Icons.settings_outlined,
                      color: Colors.grey,
                      onTap: () {}, // Kosongkan aksi
                    ),
                    */
                  ],
                ),
              ),

              // 3. FOOTER INFO
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FinTrack',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Versi 1.0.0',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, Aan!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              'FinTrack',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            icon: const Icon(Icons.settings), // Icon Gear
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionListProvider);
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(dashboardChartProvider);
          ref.invalidate(monthlyChartProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // CAROUSEL
                SizedBox(
                  height: 220,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (int index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      summaryState.when(
                        data: (data) => SummaryCard(
                          totalBalance: data['total'] ?? 0,
                          income: data['income'] ?? 0,
                          expense: data['expense'] ?? 0,
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error: $err')),
                      ),
                      // HALAMAN 2: PIE CHART
                      Consumer(
                        builder: (context, ref, child) {
                          // Ambil data chart KHUSUS dashboard (bulan ini)
                          final chartData = ref.watch(dashboardChartProvider);

                          return GestureDetector(
                            onTap: () {
                              // Navigasi ke Halaman Analisis
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ExpenseAnalysisPage(),
                                ),
                              );
                            },
                            // Pass data ke widget
                            child: ExpensePieChart(chartData: chartData),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // DOTS INDICATOR
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(2, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.teal
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // HEADER TRANSAKSI
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transaksi Terakhir',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransactionSearchPage(),
                          ),
                        );
                      },
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // LIST TRANSAKSI
                transactionListState.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada transaksi',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    }

                    final recentTransactions = transactions.take(5).toList();

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = recentTransactions[index];

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddTransactionPage(
                                  transactionToEdit: transaction,
                                ),
                              ),
                            );
                          },
                          child: TransactionItem(transaction: transaction),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) =>
                      Center(child: Text('Gagal memuat data: $err')),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddTransactionPage()),
          );
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- HELPER WIDGET UNTUK MENU ITEM YANG MODERN ---
  Widget _buildModernMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // Efek bayangan tipis agar terlihat timbul
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), // Warna background icon transparan
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
      ),
    );
  }

  // --- LOGIC EXPORT (BACKUP) ---
  // --- LOGIC EXPORT (BACKUP) ---
  Future<void> _exportData() async {
    try {
      // 1. AMBIL INSTANCE DATABASE
      // Pastikan kita mendapatkan koneksi yang aktif
      final db = await DatabaseHelper.instance.database;

      // 2. JALANKAN VACUUM (PEMBERSIHAN TOTAL)
      // Ini wajib dilakukan agar data yang sudah dihapus BENAR-BENAR HILANG dari file fisik
      await db.execute('VACUUM');

      // 3. FLUSH DATA: Tutup database
      // Menutup koneksi untuk memastikan file aman dicopy
      await DatabaseHelper.instance.closeDatabase();

      // 4. Ambil file database asli
      final dbHelper = DatabaseHelper.instance;
      final dbPath = await dbHelper.getDbPath();
      final File sourceFile = File(dbPath);

      if (!await sourceFile.exists()) {
        throw 'Database belum dibuat.';
      }

      // 5. Buat nama file backup unik
      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'fintrack_backup_$timestamp.db';

      // 6. Simpan sementara di folder cache/dokumen
      final directory = await getTemporaryDirectory();
      final backupPath = '${directory.path}/$fileName';

      // Salin file yang SUDAH BERSIH (Vacuumed)
      await sourceFile.copy(backupPath);

      // 7. Pancing database agar terbuka kembali (untuk dipakai app selanjutnya)
      await DatabaseHelper.instance.database;

      // 8. Bagikan file tersebut
      await Share.shareXFiles([
        XFile(backupPath),
      ], text: 'Backup Data FinTrack');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal Export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- LOGIC IMPORT (RESTORE) ---
  Future<void> _importData() async {
    try {
      // 1. Pilih File Backup (.db)
      final result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        final File backupFile = File(result.files.single.path!);

        // Konfirmasi User (Penting! Karena data akan ditimpa)
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Restore Data?'),
            content: const Text(
              'PERINGATAN: Semua data transaksi & kategori saat ini akan DIHAPUS dan digantikan dengan data dari file backup.\n\nLanjutkan?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Ya, Restore',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );

        if (confirm == true) {
          // 2. Tutup koneksi database aktif
          await DatabaseHelper.instance.closeForRestore();

          // 3. Timpa file database asli dengan file backup
          final dbPath = await DatabaseHelper.instance.getDbPath();
          await backupFile.copy(dbPath);

          // 4. Restart UI (Refresh Provider)
          ref.invalidate(transactionListProvider);
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(categoryListProvider); // Refresh kategori juga

          if (mounted) {
            Navigator.pop(context); // Tutup drawer
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Data berhasil dipulihkan!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal Import: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
