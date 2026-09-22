import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/funding_source.dart';
import '../providers/funding_source_provider.dart';

class FundingSourceFormPage extends ConsumerStatefulWidget {
  final FundingSource? fundingSourceToEdit;

  const FundingSourceFormPage({super.key, this.fundingSourceToEdit});

  @override
  ConsumerState<FundingSourceFormPage> createState() =>
      _FundingSourceFormPageState();
}

class _FundingSourceFormPageState extends ConsumerState<FundingSourceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _initialBalanceController = TextEditingController();
  bool _isActive = true;

  bool get _isEditMode => widget.fundingSourceToEdit != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _nameController.text = widget.fundingSourceToEdit!.name;
      _initialBalanceController.text = widget
          .fundingSourceToEdit!
          .initialBalance
          .toString();
      _isActive = widget.fundingSourceToEdit!.isActive;
    } else {
      _initialBalanceController.text = '0';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    super.dispose();
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      final initialBalance = int.tryParse(_initialBalanceController.text) ?? 0;

      try {
        if (_isEditMode) {
          final updatedFundingSource = FundingSource(
            id: widget.fundingSourceToEdit!.id,
            name: _nameController.text,
            initialBalance: initialBalance,
            isActive: _isActive,
          );
          await ref
              .read(fundingSourceListProvider.notifier)
              .updateFundingSource(updatedFundingSource);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sumber dana diperbarui!')),
            );
          }
        } else {
          await ref
              .read(fundingSourceListProvider.notifier)
              .addFundingSource(_nameController.text, initialBalance);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sumber dana dibuat!')),
            );
          }
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Sumber Dana' : 'Tambah Sumber Dana'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nama Sumber Dana',
                  hintText: 'Misal: Tunai, Rekening BCA',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.teal,
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _initialBalanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Saldo Awal (Rp)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Saldo awal wajib diisi';
                  }
                  if (int.tryParse(val) == null) return 'Harus berupa angka';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Status Aktif',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _isActive
                        ? 'Sumber dana ini akan muncul sebagai pilihan di form transaksi.'
                        : 'Sumber dana ini disembunyikan dari pilihan form transaksi.',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _isActive,
                  activeColor: Colors.teal,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ),
              const SizedBox(height: 40),
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
                    _isEditMode ? 'Simpan Perubahan' : 'Buat Sumber Dana',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
