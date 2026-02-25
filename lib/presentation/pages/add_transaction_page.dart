import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart' as entity;
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart'; // PERBAIKAN: Import ditambahkan
import '../../core/utils/app_icons.dart';

class AddTransactionPage extends ConsumerStatefulWidget {
  final entity.Transaction? transactionToEdit;

  const AddTransactionPage({super.key, this.transactionToEdit});

  @override
  ConsumerState<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends ConsumerState<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  Timer? _deleteTimer;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();

  String _type = 'expense';
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  bool _isCategoryInitialized = false;
  bool _isAmountFocused = false;

  @override
  void initState() {
    super.initState();
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
    }
  }

  @override
  void dispose() {
    _deleteTimer?.cancel();
    _titleController.dispose();
    _amountController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  // --- LOGIC KEYBOARD CUSTOM ---
  void _onKeyTap(String value) {
    String currentText = _amountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    if (currentText == '0') currentText = '';
    String newText = currentText + value;
    _formatAndSetAmount(newText);
  }

  void _onBackspace() {
    String currentText = _amountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    if (currentText.isNotEmpty) {
      String newText = currentText.substring(0, currentText.length - 1);
      _formatAndSetAmount(newText);
    }
  }

  void _onTripleZero() {
    String currentText = _amountController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    if (currentText.isNotEmpty) {
      String newText = currentText + "000";
      _formatAndSetAmount(newText);
    }
  }

  void _formatAndSetAmount(String rawString) {
    if (rawString.isEmpty) {
      _amountController.text = '';
      return;
    }
    int value = int.tryParse(rawString) ?? 0;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    _amountController.text = formatter.format(value);
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kategori terlebih dahulu!')),
        );
        return;
      }

      final title = _titleController.text;
      final amountStr = _amountController.text.replaceAll('.', '');
      final amount = int.tryParse(amountStr) ?? 0;

      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nominal harus lebih dari 0')),
        );
        return;
      }

      if (_type == 'expense') {
        final shouldProceed = await _checkSafetyNet(amount);
        if (!shouldProceed) return;
      }

      _saveToDatabase(title, amount);
    }
  }

  Future<bool> _checkSafetyNet(int newAmount) async {
    final transactionState = ref.read(transactionListProvider);
    final currentWallet = ref.read(
      selectedWalletProvider,
    ); // Sekarang Terdefinisi
    final isMonthlyWallet = currentWallet?.isMonthly ?? true;

    if (!transactionState.hasValue) return true;

    final allTransactions = transactionState.value!;
    final now = DateTime.now();

    final activeTransactions = isMonthlyWallet
        ? allTransactions.where((t) {
            return t.date.month == now.month && t.date.year == now.year;
          }).toList()
        : allTransactions;

    // 1. CEK GLOBAL
    int totalIncome = 0;
    int totalExpense = 0;

    for (var t in activeTransactions) {
      if (widget.transactionToEdit != null &&
          t.id == widget.transactionToEdit!.id)
        continue;

      if (t.type == 'income')
        totalIncome += t.amount;
      else
        totalExpense += t.amount;
    }

    final currentBalance = totalIncome - totalExpense;
    final balanceAfterTransaction = currentBalance - newAmount;

    // 2. CEK KATEGORI
    bool isOverCategory = false;
    String categoryWarning = '';

    if (_selectedCategory!.budget > 0) {
      int categoryExpense = 0;
      // PERBAIKAN: Menggunakan activeTransactions, bukan thisMonthTransactions
      for (var t in activeTransactions) {
        if (widget.transactionToEdit != null &&
            t.id == widget.transactionToEdit!.id)
          continue;

        if (t.categoryId == _selectedCategory!.id && t.type == 'expense') {
          categoryExpense += t.amount;
        }
      }

      // PERBAIKAN: Menambahkan .toInt() untuk komparasi tipe data
      if (categoryExpense + newAmount > _selectedCategory!.budget.toInt()) {
        isOverCategory = true;
        categoryWarning =
            'Budget ${_selectedCategory!.name} akan jebol (Over)!';
      }
    }

    if (balanceAfterTransaction < 0 || isOverCategory) {
      return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Peringatan Keuangan'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (balanceAfterTransaction < 0) ...[
                    const Text(
                      '⚠️ SISA SALDO TIDAK CUKUP!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Saldo tersedia: ${_formatRupiah(currentBalance)}'),
                    Text(
                      'Setelah transaksi: ${_formatRupiah(balanceAfterTransaction)} (MINUS)',
                    ),
                    const Divider(),
                  ],
                  if (isOverCategory) ...[
                    Text(
                      '⚠️ $categoryWarning',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 10),
                  const Text('Apakah Anda yakin tetap ingin menyimpan?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Tetap Simpan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ) ??
          false;
    }

    return true;
  }

  void _saveToDatabase(String title, int amount) async {
    try {
      if (widget.transactionToEdit == null) {
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
      } else {
        final updatedTransaction = entity.Transaction(
          id: widget.transactionToEdit!.id,
          title: title,
          amount: amount,
          type: _type,
          categoryId: _selectedCategory!.id!,
          date: _selectedDate,
        );
        await ref
            .read(transactionListProvider.notifier)
            .updateTransaction(updatedTransaction);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatRupiah(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  void _showCategoryPicker() {
    setState(() => _isAmountFocused = false);
    FocusManager.instance.primaryFocus?.unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, child) {
                final categoryListState = ref.watch(categoryListProvider);
                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Pilih Kategori',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: categoryListState.when(
                        data: (categories) {
                          final filtered = categories
                              .where((c) => c.type == _type)
                              .toList();
                          return GridView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.8,
                                ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final cat = filtered[index];
                              final isSelected =
                                  _selectedCategory?.id == cat.id;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = cat;
                                    _isCategoryInitialized = true;
                                  });
                                  Navigator.pop(context);
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Color(
                                          cat.color,
                                        ).withOpacity(isSelected ? 0.4 : 0.1),
                                        shape: BoxShape.circle,
                                        border: isSelected
                                            ? Border.all(
                                                color: Color(cat.color),
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      child: Icon(
                                        AppIcons.getIcon(cat.icon),
                                        color: Color(cat.color),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      cat.name,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('$err')),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _presentDatePicker() {
    setState(() => _isAmountFocused = false);
    FocusManager.instance.primaryFocus?.unfocus();
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
    final categoryListState = ref.watch(categoryListProvider);
    final isEditMode = widget.transactionToEdit != null;

    categoryListState.whenData((categories) {
      final filteredCategories = categories
          .where((c) => c.type == _type)
          .toList();
      if (isEditMode && !_isCategoryInitialized && _selectedCategory == null) {
        try {
          final oldCategory = filteredCategories.firstWhere(
            (c) => c.id == widget.transactionToEdit!.categoryId,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted)
              setState(() {
                _selectedCategory = oldCategory;
                _isCategoryInitialized = true;
              });
          });
        } catch (_) {}
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Transaksi' : 'Tambah Transaksi'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _type = newSelection.first;
                            _selectedCategory = null;
                            _isCategoryInitialized = false;
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.selected))
                                  return _type == 'expense'
                                      ? Colors.red.shade100
                                      : Colors.green.shade100;
                                return Colors.transparent;
                              }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        _titleFocusNode.unfocus();
                        setState(() {
                          _isAmountFocused = true;
                        });
                      },
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [CapitalizeWordsInputFormatter()],
                      onTap: () {
                        setState(() => _isAmountFocused = false);
                      },
                      decoration: InputDecoration(
                        labelText: 'Judul Transaksi',
                        hintText: 'Cth: Makan Siang',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Judul wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      readOnly: true,
                      showCursor: true,
                      onTap: () {
                        _titleFocusNode.unfocus();
                        setState(() => _isAmountFocused = true);
                      },
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nominal (Rp)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: _isAmountFocused
                            ? OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.teal,
                                  width: 2,
                                ),
                              )
                            : null,
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Nominal wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _showCategoryPicker,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.category, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedCategory?.name ?? 'Pilih Kategori',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedCategory == null
                                      ? Colors.grey[700]
                                      : Colors.black,
                                ),
                              ),
                            ),
                            if (_selectedCategory != null)
                              Icon(
                                AppIcons.getIcon(_selectedCategory!.icon),
                                color: Color(_selectedCategory!.color),
                              ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                          DateFormat(
                            'dd MMMM yyyy',
                            'id_ID',
                          ).format(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
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
          ),
          if (_isAmountFocused)
            Container(
              color: Colors.grey[100],
              padding: EdgeInsets.only(
                top: 10,
                bottom: 20 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildNumKey('1'),
                      _buildNumKey('2'),
                      _buildNumKey('3'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildNumKey('4'),
                      _buildNumKey('5'),
                      _buildNumKey('6'),
                    ],
                  ),
                  Row(
                    children: [
                      _buildNumKey('7'),
                      _buildNumKey('8'),
                      _buildNumKey('9'),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _onTripleZero,
                          child: _buildKeyContainer('000'),
                        ),
                      ),
                      _buildNumKey('0'),
                      Expanded(
                        child: GestureDetector(
                          onTap: _onBackspace,
                          onLongPressStart: (_) {
                            _deleteTimer = Timer.periodic(
                              const Duration(milliseconds: 100),
                              (timer) => _onBackspace(),
                            );
                          },
                          onLongPressEnd: (_) => _deleteTimer?.cancel(),
                          child: Container(
                            height: 60,
                            margin: const EdgeInsets.all(4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 1),
                              ],
                            ),
                            child: const Icon(
                              Icons.backspace,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _showCategoryPicker,
                        icon: const Icon(Icons.category_outlined),
                        label: const Text('Pilih Kategori (Tab)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeyContainer(String text) {
    return Container(
      height: 60,
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 1)],
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNumKey(String value) {
    return Expanded(
      child: InkWell(
        onTap: () => _onKeyTap(value),
        child: Container(
          height: 60,
          margin: const EdgeInsets.all(4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 1)],
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class CapitalizeWordsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    String newText = newValue.text
        .split(' ')
        .map((word) {
          if (word.isNotEmpty) return word[0].toUpperCase() + word.substring(1);
          return '';
        })
        .join(' ');
    return TextEditingValue(text: newText, selection: newValue.selection);
  }
}
