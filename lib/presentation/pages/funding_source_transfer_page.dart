import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/funding_source.dart';
import '../providers/funding_source_provider.dart';
import '../providers/funding_source_transfer_provider.dart';

class FundingSourceTransferPage extends ConsumerStatefulWidget {
  const FundingSourceTransferPage({super.key});

  @override
  ConsumerState<FundingSourceTransferPage> createState() =>
      _FundingSourceTransferPageState();
}

class _FundingSourceTransferPageState
    extends ConsumerState<FundingSourceTransferPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  FundingSource? _fromSource;
  FundingSource? _toSource;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _presentDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fromSource == null || _toSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih sumber dana asal & tujuan!')),
      );
      return;
    }

    if (_fromSource!.id == _toSource!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sumber dana asal & tujuan tidak boleh sama!'),
        ),
      );
      return;
    }

    final amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0')),
      );
      return;
    }

    final balances = await ref.read(fundingSourceBalancesProvider.future);
    final fromBalance = balances[_fromSource!.id] ?? 0;

    if (amount > fromBalance) {
      final proceed =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Peringatan Saldo'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo ${_fromSource!.name} tidak cukup!',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Saldo tersedia: ${formatRupiah(fromBalance)}'),
                  const SizedBox(height: 10),
                  const Text('Apakah Anda yakin tetap ingin lanjutkan?'),
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
                    'Tetap Lanjutkan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ) ??
          false;

      if (!proceed) return;
    }

    try {
      await ref
          .read(fundingSourceTransferListProvider.notifier)
          .addTransfer(
            fromSourceId: _fromSource!.id!,
            toSourceId: _toSource!.id!,
            amount: amount,
            date: _selectedDate,
            note: _noteController.text.isEmpty ? null : _noteController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transfer berhasil dicatat!')),
        );
        _amountController.clear();
        _noteController.clear();
        setState(() {
          _fromSource = null;
          _toSource = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fundingSourceListAsync = ref.watch(fundingSourceListProvider);
    final transferListAsync = ref.watch(fundingSourceTransferListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transfer Sumber Dana')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fundingSourceListAsync.when(
                    data: (fundingSources) {
                      final activeSources = fundingSources
                          .where((fs) => fs.isActive)
                          .toList();
                      return Column(
                        children: [
                          DropdownButtonFormField<FundingSource>(
                            value: _fromSource,
                            decoration: InputDecoration(
                              labelText: 'Dari Sumber Dana',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.arrow_upward),
                            ),
                            items: activeSources
                                .map(
                                  (fs) => DropdownMenuItem(
                                    value: fs,
                                    child: Text(fs.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _fromSource = value),
                            validator: (value) =>
                                value == null ? 'Pilih sumber asal' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<FundingSource>(
                            value: _toSource,
                            decoration: InputDecoration(
                              labelText: 'Ke Sumber Dana',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.arrow_downward),
                            ),
                            items: activeSources
                                .map(
                                  (fs) => DropdownMenuItem(
                                    value: fs,
                                    child: Text(fs.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _toSource = value),
                            validator: (value) =>
                                value == null ? 'Pilih sumber tujuan' : null,
                          ),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error: $err'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Nominal (Rp)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Nominal wajib diisi';
                      }
                      if (int.tryParse(val) == null) return 'Harus angka';
                      return null;
                    },
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'Catatan (Opsional)',
                      hintText: 'Misal: Tarik tunai ATM',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.note_alt_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                      child: const Text(
                        'Simpan Transfer',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Riwayat Transfer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            transferListAsync.when(
              data: (transfers) {
                if (transfers.isEmpty) {
                  return const Text('Belum ada transfer');
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transfers.length,
                  itemBuilder: (context, index) {
                    final tr = transfers[index];
                    return Dismissible(
                      key: Key('transfer_${tr.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        await ref
                            .read(fundingSourceTransferListProvider.notifier)
                            .deleteTransfer(tr.id!);
                      },
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.swap_horiz,
                            color: Colors.indigo,
                          ),
                          title: Text(
                            '${tr.fromSource?.name ?? '-'}  →  ${tr.toSource?.name ?? '-'}',
                          ),
                          subtitle: Text(
                            '${formatDate(tr.date)}${tr.note != null ? ' • ${tr.note}' : ''}',
                          ),
                          trailing: Text(
                            formatRupiah(tr.amount),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }
}
