import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart'; // <--- IMPORT WAJIB

import '../../core/utils/app_icons.dart';
import '../../domain/entities/category.dart';
import '../providers/category_provider.dart';
import '../providers/usecase_providers.dart';

class CategoryFormPage extends ConsumerStatefulWidget {
  // Parameter opsional untuk mode EDIT
  final Category? categoryToEdit;

  const CategoryFormPage({super.key, this.categoryToEdit});

  @override
  ConsumerState<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends ConsumerState<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _type = 'expense';
  String _selectedIcon = 'category';
  int _selectedColor = 0xFF9E9E9E;

  // Flag edit mode
  bool get _isEditMode => widget.categoryToEdit != null;

  @override
  void initState() {
    super.initState();
    // Jika Mode Edit: Isi form dengan data lama
    if (_isEditMode) {
      final c = widget.categoryToEdit!;
      _nameController.text = c.name;
      _type = c.type;
      _selectedIcon = c.icon;
      _selectedColor = c.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // --- LOGIC PICK ICON ---
  Future<void> _pickIcon() async {
    // Membuka dialog icon picker
    IconData? icon = await showIconPicker(
      context,
      iconPackModes: [IconPack.material], // Gunakan Material Icons
      title: const Text('Pilih Ikon'),
      searchHintText: 'Cari ikon...',
      closeChild: const Text('Tutup'),
    );

    if (icon != null) {
      setState(() {
        // Simpan CodePoint (ID Angka) sebagai String
        _selectedIcon = icon.codePoint.toString();
      });
    }
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (_isEditMode) {
          // --- LOGIC UPDATE ---
          final updatedCategory = Category(
            id: widget.categoryToEdit!.id,
            name: _nameController.text,
            icon: _selectedIcon,
            color: _selectedColor,
            type: _type,
          );

          final updateUseCase = ref.read(updateCategoryProvider);
          await updateUseCase(updatedCategory);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kategori berhasil diperbarui!')),
            );
          }
        } else {
          // --- LOGIC TAMBAH BARU ---
          final newCategory = Category(
            name: _nameController.text,
            icon: _selectedIcon,
            color: _selectedColor,
            type: _type,
          );

          final addUseCase = ref.read(addCategoryProvider);
          await addUseCase(newCategory);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kategori berhasil dibuat!')),
            );
          }
        }

        // Refresh List & Tutup Halaman
        ref.invalidate(categoryListProvider);
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

  final List<Color> _availableColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Kategori' : 'Buat Kategori Baru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. INPUT NAMA
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [CapitalizeWordsInputFormatter()],
                decoration: InputDecoration(
                  labelText: 'Nama Kategori',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(
                    AppIcons.getIcon(_selectedIcon),
                    color: Color(_selectedColor),
                  ),
                ),
                validator: (val) => val!.isEmpty ? 'Nama wajib diisi' : null,
              ),

              const SizedBox(height: 20),

              // 2. PILIH TIPE
              Text('Jenis Kategori', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Pengeluaran')),
                  ButtonSegment(value: 'income', label: Text('Pemasukan')),
                ],
                selected: {_type},
                onSelectionChanged: _isEditMode
                    ? null
                    : (val) => setState(() => _type = val.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _type == 'expense'
                          ? Colors.red.shade100
                          : Colors.green.shade100;
                    }
                    return null;
                  }),
                ),
              ),
              if (_isEditMode)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    '*Jenis kategori tidak bisa diubah saat edit',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 10),

              // 3. PILIH WARNA
              const Text(
                'Pilih Warna',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableColors.map((color) {
                  final isSelected = _selectedColor == color.value;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color.value),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 10),

              // 4. PILIH ICON (LOGIC BARU)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ikon',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _pickIcon, // Panggil fungsi picker
                    icon: const Icon(Icons.search),
                    label: const Text('Cari Icon Lain'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Tampilan Preview Icon yang Sedang Dipilih
              Center(
                child: GestureDetector(
                  onTap: _pickIcon,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Color(_selectedColor).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(_selectedColor),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      AppIcons.getIcon(_selectedIcon),
                      size: 40,
                      color: Color(_selectedColor),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "Tap icon di atas untuk mengganti",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 20),
              const Text("Pilihan Cepat:"),
              const SizedBox(height: 10),

              // Pilihan Cepat (Grid Kecil dari icon bawaan)
              Container(
                height: 150,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6, // Lebih padat dari sebelumnya
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: AppIcons.map.length,
                  itemBuilder: (context, index) {
                    final key = AppIcons.map.keys.elementAt(index);
                    final iconData = AppIcons.map.values.elementAt(index);
                    final isSelected = _selectedIcon == key;

                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = key),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.teal.shade50
                              : Colors.transparent,
                          border: isSelected
                              ? Border.all(color: Colors.teal)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          iconData,
                          color: isSelected ? Colors.teal : Colors.grey,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // 5. TOMBOL SIMPAN
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
                    _isEditMode ? 'Simpan Perubahan' : 'Buat Kategori',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

class CapitalizeWordsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String text = newValue.text;
    String newText = text
        .split(' ')
        .map((word) {
          if (word.isNotEmpty) {
            return word[0].toUpperCase() + word.substring(1);
          }
          return '';
        })
        .join(' ');

    return TextEditingValue(text: newText, selection: newValue.selection);
  }
}
