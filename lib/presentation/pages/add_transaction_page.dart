import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart'
    as entity; // Alias biar tidak bentrok
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';

import '../../core/utils/app_icons.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  // Parameter opsional: Jika diisi, berarti mode EDIT. Jika null, mode TAMBAH.
  final entity.Transaction? transactionToEdit;

  const AddTransactionPage({super.key, this.transactionToEdit});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller input
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  // State halaman
  String _type = 'expense'; // Default: Pengeluaran
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;

  // Flag untuk memastikan inisialisasi kategori hanya berjalan sekali
  bool _isCategoryInitialized = false;

  @override
  void initState() {
    super.initState();
    // LOGIC: Jika ada data 'transactionToEdit', isi form dengan data lama
    if (widget.transactionToEdit != null) {
      final t = widget.transactionToEdit!;
      _titleController.text = t.title;
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: '',
        decimalDigits: 0,
      );
      _amountController.text = formatter.format(t.amount);
      _type = t.type;
      _selectedDate = t.date;
      // Catatan: _selectedCategory di-handle di method build() setelah data kategori siap
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // LOGIC SIMPAN / UPDATE DATA
  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      // Validasi manual: User harus pilih kategori
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kategori terlebih dahulu!')),
        );
        return;
      }

      final title = _titleController.text;
      // Menghapus titik jika user mengetik format ribuan manual (opsional safety)
      final amount = int.parse(_amountController.text.replaceAll('.', ''));

      try {
        if (widget.transactionToEdit == null) {
          // --- MODE TAMBAH BARU ---
          final newTransaction = entity.Transaction(
            title: title,
            amount: amount,
            type: _type,
            categoryId: _selectedCategory!.id!,
            date: _selectedDate,
          );

          await ref
              .read(transactionListProvider.notifier)
              .addTransaction(newTransaction);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaksi berhasil disimpan!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // --- MODE EDIT (UPDATE) ---
          final updatedTransaction = entity.Transaction(
            id: widget
                .transactionToEdit!
                .id, // PENTING: ID Transaksi lama harus dibawa
            title: title,
            amount: amount,
            type: _type,
            categoryId: _selectedCategory!.id!,
            date: _selectedDate,
          );

          await ref
              .read(transactionListProvider.notifier)
              .updateTransaction(updatedTransaction);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Perubahan berhasil disimpan!'),
                backgroundColor: Colors.teal,
              ),
            );
          }
        }

        // Kembali ke Dashboard setelah sukses
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Date Picker UI
  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ambil list kategori dari Provider
    final categoryListState = ref.watch(categoryListProvider);
    final isEditMode = widget.transactionToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Transaksi' : 'Tambah Transaksi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOGGLE INCOME / EXPENSE
              Center(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'expense',
                      label: Text('Pengeluaran'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: 'income',
                      label: Text('Pemasukan'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _type = newSelection.first;
                      _selectedCategory =
                          null; // Reset kategori saat ganti tipe
                      _isCategoryInitialized = false; // Reset flag inisialisasi
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return _type == 'expense'
                            ? Colors.red.shade100
                            : Colors.green.shade100;
                      }
                      return Colors.transparent;
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 2. INPUT TITLE (Dengan Autofocus)
              TextFormField(
                controller: _titleController,
                autofocus: true, // <--- UX: Keyboard langsung muncul
                textInputAction:
                    TextInputAction.next, // <--- UX: Tombol Enter jadi Next
                textCapitalization: TextCapitalization.words,
                inputFormatters: [CapitalizeWordsInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Judul Transaksi',
                  hintText: 'Cth: Makan Siang',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 3. INPUT NOMINAL
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Hanya angka
                  CurrencyInputFormatter(), // Format Ribuan otomatis
                ],
                decoration: InputDecoration(
                  labelText: 'Nominal (Rp)',
                  hintText: 'Cth: 15.000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nominal tidak boleh kosong';
                  }
                  // Bersihkan titik sebelum validasi angka
                  final cleanValue = value.replaceAll('.', '');
                  if (int.tryParse(cleanValue) == null ||
                      int.parse(cleanValue) <= 0) {
                    return 'Masukkan nominal yang valid';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // 4. DROPDOWN KATEGORI
              categoryListState.when(
                data: (categories) {
                  // Filter kategori sesuai tipe (Income/Expense)
                  final filteredCategories = categories
                      .where((c) => c.type == _type)
                      .toList();

                  // --- LOGIC AUTO-SELECT KATEGORI LAMA (Saat Edit) ---
                  if (isEditMode &&
                      !_isCategoryInitialized &&
                      _selectedCategory == null) {
                    try {
                      // Cari kategori di list yang ID-nya sama dengan transaksi lama
                      final oldCategory = filteredCategories.firstWhere(
                        (c) => c.id == widget.transactionToEdit!.categoryId,
                      );

                      // Jalankan setelah frame selesai agar tidak bentrok dengan proses build
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _selectedCategory = oldCategory;
                            _isCategoryInitialized =
                                true; // Tandai sudah diinisialisasi
                          });
                        }
                      });
                    } catch (e) {
                      // Jika kategori lama tidak ditemukan (misal sudah dihapus), biarkan kosong
                    }
                  }

                  return DropdownButtonFormField<Category>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: filteredCategories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(
                              AppIcons.getIcon(cat.icon),
                              color: Color(cat.color),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _isCategoryInitialized = true;
                      });
                    },
                  );
                },
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (err, _) => Text(
                  'Gagal: $err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),

              const SizedBox(height: 16),

              // 5. DATE PICKER
              InkWell(
                onTap: _presentDatePicker,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tanggal',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 6. TOMBOL SIMPAN
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEditMode ? 'Simpan Perubahan' : 'Simpan Transaksi',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Letakkan di paling bawah file, setelah tutup kurung kurawal terakhir
class CapitalizeWordsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final text = newValue.text;
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      // Huruf besar jika: Karakter pertama ATAU karakter sebelumnya adalah spasi
      if (i == 0 || text[i - 1] == ' ') {
        buffer.write(text[i].toUpperCase());
      } else {
        buffer.write(text[i]);
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: newValue.selection,
    );
  }
}

// Letakkan di paling bawah file add_transaction_page.dart
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Jika kosong, biarkan kosong
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // 2. Hapus semua karakter selain angka (bersihkan format lama)
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Jika hasilnya kosong (misal user hapus semua), return kosong
    if (newText.isEmpty) return newValue.copyWith(text: '');

    // 3. Parse ke integer lalu format ulang
    int value = int.parse(newText);
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    String newString = formatter.format(value);

    // 4. Kembalikan text baru dengan kursor di akhir
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
