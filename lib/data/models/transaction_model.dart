import '../../domain/entities/transaction.dart';
import 'category_model.dart'; // Pastikan import ini ada

class TransactionModel extends Transaction {
  const TransactionModel({
    super.id,
    required super.title,
    required super.amount,
    required super.type,
    required super.categoryId,
    required super.date,
    super.note,
    super.category,
  });

  // --- 1. FACTORY UTAMA (fromMap) ---
  // Digunakan oleh Repository untuk mengubah data mentah DB menjadi Model
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      type: map['type'],
      categoryId: map['category_id'],
      // Konversi String ISO8601 ke DateTime
      date: DateTime.parse(map['date']),
      note: map['note'],

      // --- LOGIC JOIN (PENTING UNTUK SEARCH) ---
      // Cek apakah map memiliki data kategori (hasil dari query JOIN)
      // Jika ya, buat object CategoryModel agar Icon & Warna muncul di UI
      category: map['category_name'] != null
          ? CategoryModel(
              id: map['category_id'],
              name: map['category_name'],
              icon: map['category_icon'],
              color: map['category_color'],
              type: map['category_type'],
            )
          : null,
    );
  }

  // Alias: Jika ada kode lain yang memanggil fromJson, alihkan ke fromMap
  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel.fromMap(json);

  // --- 2. METHOD toEntity (WAJIB ADA) ---
  // Digunakan untuk mengubah Model (Data Layer) ke Entity (Domain Layer)
  Transaction toEntity() {
    return Transaction(
      id: id,
      title: title,
      amount: amount,
      type: type,
      categoryId: categoryId,
      date: date,
      note: note,
      category: category, // Bawa serta object kategori jika ada
    );
  }

  // --- 3. METHOD toJson / toMap ---
  // Digunakan saat menyimpan data ke SQLite
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'note': note,
    };
  }
}
