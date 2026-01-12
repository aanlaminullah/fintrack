import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/entities/transaction.dart';
import '../utils/currency_formatter.dart'; // Pastikan path ini sesuai

// ... import tetap sama ...

class ReportService {
  // --- 1. GENERATE & SHARE PDF (Updated) ---
  // Tambahkan parameter start dan end date
  static Future<void> generatePdfReport(
    List<Transaction> transactions,
    DateTime start,
    DateTime end,
  ) async {
    final pdf = pw.Document();

    // Format tanggal untuk Header (Contoh: 01 Jan 2026 - 31 Jan 2026)
    final periodString =
        '${DateFormat('dd MMM yyyy', 'id_ID').format(start)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(end)}';

    // Hitung Ringkasan
    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0, (sum, t) => sum + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold(0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpense;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header Laporan
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Laporan Keuangan',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Dibuat: ${DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  // Tampilkan Periode Laporan
                  pw.Text(
                    'Periode: $periodString',
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),

            // ... (Kode Ringkasan Saldo Box TETAP SAMA seperti sebelumnya) ...
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem('Pemasukan', totalIncome, PdfColors.green),
                  _buildSummaryItem('Pengeluaran', totalExpense, PdfColors.red),
                  _buildSummaryItem('Sisa Saldo', balance, PdfColors.blue),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Tabel Transaksi
            pw.TableHelper.fromTextArray(
              headers: ['Tanggal', 'Judul', 'Kategori', 'Tipe', 'Nominal'],
              data: transactions.map((t) {
                return [
                  DateFormat('dd/MM/yy').format(t.date),
                  t.title,
                  t.category?.name ?? '-',
                  t.type == 'income' ? 'Masuk' : 'Keluar',
                  formatRupiah(t.amount),
                ];
              }).toList(),
              // ... (Style tabel TETAP SAMA) ...
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                ),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {4: pw.Alignment.centerRight},
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_FinTrack_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  // ... (Fungsi CSV dan _buildSummaryItem TETAP SAMA) ...
  static pw.Widget _buildSummaryItem(String label, int amount, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
        ),
        pw.Text(
          formatRupiah(amount),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  static Future<void> generateCsvReport(List<Transaction> transactions) async {
    // ... (Kode CSV TETAP SAMA, tidak perlu diubah) ...
    // Copy paste dari kode sebelumnya
    List<List<dynamic>> rows = [
      ["Tanggal", "Judul", "Kategori", "Tipe", "Catatan", "Nominal"],
    ];

    for (var t in transactions) {
      rows.add([
        DateFormat('yyyy-MM-dd HH:mm').format(t.date),
        t.title,
        t.category?.name ?? 'Tanpa Kategori',
        t.type,
        t.note ?? '',
        t.amount,
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final path =
        "${directory.path}/Laporan_FinTrack_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv";
    final file = File(path);
    await file.writeAsString(csvData);
    await Share.shareXFiles([
      XFile(path),
    ], text: 'Laporan Transaksi FinTrack (CSV)');
  }
}
