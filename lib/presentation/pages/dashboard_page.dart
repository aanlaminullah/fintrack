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
import '../../core/services/report_service.dart'; // Akses service yang baru dibuat
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';

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
                      onTap: _showBackupOptions,
                    ),

                    // MENU IMPORT
                    _buildModernMenuItem(
                      context,
                      title: 'Restore Data (Import)',
                      icon: Icons.download_for_offline,
                      color: Colors.orange,
                      onTap: _importData,
                    ),

                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 10),

                    // MENU LAPORAN (BARU)
                    _buildModernMenuItem(
                      context,
                      title: 'Laporan Keuangan',
                      icon: Icons.print,
                      color: Colors.purple,
                      onTap: () =>
                          _showExportOptions(context, ref), // Panggil modal
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

  // --- MENU PILIHAN BACKUP (FIX OVERFLOW) ---
  void _showBackupOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(
              context,
            ).viewPadding.bottom, // Padding Samsung
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            // HAPUS height: 280, biarkan dia menyesuaikan isi
            child: Column(
              mainAxisSize:
                  MainAxisSize.min, // <--- PENTING: Agar tidak overflow
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Backup Data Database',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Amankan data transaksi Anda agar tidak hilang.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // PILIHAN 1: SIMPAN KE PENYIMPANAN
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.save_as, color: Colors.blue),
                  ),
                  title: const Text('Simpan ke Penyimpanan'),
                  subtitle: const Text('Pilih lokasi simpan manual'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _processBackup(action: 'save');
                  },
                ),

                const SizedBox(height: 10),

                // PILIHAN 2: SHARE
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.share, color: Colors.green),
                  ),
                  title: const Text('Bagikan File Backup'),
                  subtitle: const Text('Kirim ke WhatsApp / Drive'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _processBackup(action: 'share');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- LOGIC PROSES BACKUP (FIX BYTES REQUIRED) ---
  Future<void> _processBackup({required String action}) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sedang memproses backup...')),
        );
      }

      // 1. VACUUM & CLOSE DATABASE
      final db = await DatabaseHelper.instance.database;
      await db.execute('VACUUM');
      await DatabaseHelper.instance.closeDatabase();

      // 2. SIAPKAN FILE DARI DATABASE ASLI
      final dbHelper = DatabaseHelper.instance;
      final dbPath = await dbHelper.getDbPath();
      final File sourceFile = File(dbPath);

      if (!await sourceFile.exists()) throw 'Database tidak ditemukan.';

      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'fintrack_backup_$timestamp.db';

      // Copy ke Cache dulu
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      final File tempFile = await sourceFile.copy(tempPath);

      // 3. BUKA KEMBALI DATABASE (Agar aplikasi tidak error)
      await DatabaseHelper.instance.database;

      // 4. EKSEKUSI
      if (action == 'share') {
        // --- SHARE ---
        await Share.shareXFiles([
          XFile(tempPath),
        ], text: 'Backup Data FinTrack');
      } else if (action == 'save') {
        // --- SIMPAN KE FILE (FIX) ---
        // Baca file menjadi bytes (data mentah)
        final Uint8List fileBytes = await tempFile.readAsBytes();

        // Simpan menggunakan bytes (Ini akan membuka dialog simpan Android)
        final String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan File Backup',
          fileName: fileName,
          bytes: fileBytes, // <--- WAJIB DIISI UNTUK ANDROID/IOS
        );

        if (outputFile != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Backup berhasil disimpan!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Penyimpanan dibatalkan.')),
            );
          }
        }
      }
    } catch (e) {
      await DatabaseHelper.instance.database; // Safety open

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal Backup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  _showExportOptions(BuildContext context, WidgetRef ref) {
    // Default: Bulan Ini
    final now = DateTime.now();
    DateTime selectedMonth = DateTime(now.year, now.month);
    DateTimeRange customRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );

    String selectedMode = 'monthly';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // Tetap biarkan true
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            DateTime getFinalStart() {
              if (selectedMode == 'monthly') {
                return DateTime(selectedMonth.year, selectedMonth.month, 1);
              } else {
                return customRange.start;
              }
            }

            DateTime getFinalEnd() {
              if (selectedMode == 'monthly') {
                return DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
              } else {
                return customRange.end;
              }
            }

            // --- PERBAIKAN DI SINI ---
            // Kita bungkus Container dengan Padding yang membaca 'viewPadding.bottom'
            // Ini akan otomatis mengangkat konten setinggi tombol navigasi HP Samsung Anda
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  0,
                ), // Padding bawah 0 karena sudah dihandle viewPadding
                height: 450,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Periode Laporan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- PILIHAN TIPE PERIODE (TAB) ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setModalState(() => selectedMode = 'monthly'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedMode == 'monthly'
                                      ? Colors.teal
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Per Bulan',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selectedMode == 'monthly'
                                        ? Colors.white
                                        : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setModalState(() => selectedMode = 'custom'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: selectedMode == 'custom'
                                      ? Colors.teal
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Custom Tanggal',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selectedMode == 'custom'
                                        ? Colors.white
                                        : Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- TAMPILAN INPUT SESUAI MODE ---
                    if (selectedMode == 'monthly') ...[
                      const Text(
                        'Pilih Bulan:',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await _showMonthPicker(
                            context,
                            selectedMonth,
                          );
                          if (picked != null) {
                            setModalState(() {
                              selectedMonth = picked;
                            });
                          }
                        },
                        child: _buildDateContainer(
                          icon: Icons.calendar_month,
                          text: DateFormat(
                            'MMMM yyyy',
                            'id_ID',
                          ).format(selectedMonth),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Pilih Rentang Tanggal:',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            initialDateRange: customRange,
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Colors.teal,
                                    onPrimary: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setModalState(() {
                              customRange = picked;
                            });
                          }
                        },
                        child: _buildDateContainer(
                          icon: Icons.date_range,
                          text:
                              '${DateFormat('dd MMM yyyy', 'id_ID').format(customRange.start)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(customRange.end)}',
                        ),
                      ),
                    ],

                    const Spacer(),
                    const Divider(),
                    const Text(
                      'Export Sebagai:',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 10),

                    // TOMBOL EKSEKUSI (PDF / CSV)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _processAndExport(
                              ref,
                              ctx,
                              getFinalStart(),
                              getFinalEnd(),
                              'pdf',
                            ),
                            icon: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'PDF',
                              style: TextStyle(color: Colors.red),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _processAndExport(
                              ref,
                              ctx,
                              getFinalStart(),
                              getFinalEnd(),
                              'csv',
                            ),
                            icon: const Icon(
                              Icons.table_view,
                              color: Colors.green,
                            ),
                            label: const Text(
                              'Excel',
                              style: TextStyle(color: Colors.green),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.green),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20), // Jarak aman tambahan
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _processAndExport(
    WidgetRef ref,
    BuildContext ctx,
    DateTime start,
    DateTime end,
    String type,
  ) async {
    Navigator.pop(ctx); // Tutup modal dulu

    final transactionState = ref.read(transactionListProvider);

    if (transactionState.hasValue) {
      final allData = transactionState.value!;

      // 1. FILTER BERDASARKAN TANGGAL
      final filteredData = allData.where((t) {
        // Normalisasi tanggal agar jam tidak mempengaruhi
        final tDate = DateTime(t.date.year, t.date.month, t.date.day);
        final sDate = DateTime(start.year, start.month, start.day);
        final eDate = DateTime(end.year, end.month, end.day);

        // Logika: Tanggal transaksi >= start DAN <= end
        return (tDate.isAtSameMomentAs(sDate) || tDate.isAfter(sDate)) &&
            (tDate.isAtSameMomentAs(eDate) || tDate.isBefore(eDate));
      }).toList();

      if (filteredData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada transaksi di periode ini!'),
            ),
          );
        }
        return;
      }

      // 2. SORTING (TERLAMA KE TERBARU)
      // Tanggal kecil (lama) di atas, besar (baru) di bawah
      filteredData.sort((a, b) => a.date.compareTo(b.date));

      // 3. EKSEKUSI EXPORT
      if (type == 'pdf') {
        // Pass start & end date untuk Header PDF
        await ReportService.generatePdfReport(filteredData, start, end);
      } else {
        await ReportService.generateCsvReport(filteredData);
      }
    }
  }

  // --- HELPER WIDGET UNTUK KOTAK TANGGAL ---
  Widget _buildDateContainer({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          const Icon(Icons.arrow_drop_down, color: Colors.grey),
        ],
      ),
    );
  }

  // --- HELPER CUSTOM MONTH PICKER DIALOG ---
  Future<DateTime?> _showMonthPicker(
    BuildContext context,
    DateTime initialDate,
  ) async {
    DateTime tempDate = initialDate;

    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(
                      () => tempDate = DateTime(
                        tempDate.year - 1,
                        tempDate.month,
                      ),
                    ),
                  ),
                  Text(
                    tempDate.year.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(
                      () => tempDate = DateTime(
                        tempDate.year + 1,
                        tempDate.month,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: GridView.builder(
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                  ),
                  itemBuilder: (context, index) {
                    final monthDate = DateTime(tempDate.year, index + 1);
                    final isSelected =
                        monthDate.year == initialDate.year &&
                        monthDate.month == initialDate.month;
                    // Cek apakah ini bulan yang dipilih di dialog saat ini
                    final isCurrentTemp = monthDate.month == tempDate.month;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context, monthDate);
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrentTemp
                              ? Colors.teal
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrentTemp
                              ? null
                              : Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          DateFormat('MMM', 'id_ID').format(monthDate),
                          style: TextStyle(
                            color: isCurrentTemp
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
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
