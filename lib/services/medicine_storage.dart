import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';

class MedicineStorage {
  static const String _key = 'medicines_list';
  static const String _counterKey = 'medicine_id_counter';

  // Benzersiz küçük ID üret (32-bit safe)
  static Future<int> _getNextId() async {
    final prefs = await SharedPreferences.getInstance();
    int counter = prefs.getInt(_counterKey) ?? 1;
    await prefs.setInt(_counterKey, counter + 1);
    return counter;
  }

  // Tüm ilaçları kaydet
  static Future<bool> saveMedicines(List<Medicine> medicines) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> medicinesJson = medicines.map((medicine) {
        return jsonEncode(medicine.toJson());
      }).toList();

      return await prefs.setStringList(_key, medicinesJson);
    } catch (e) {
      print('İlaçları kaydetme hatası: $e');
      return false;
    }
  }

  // Tüm ilaçları yükle
  static Future<List<Medicine>> loadMedicines() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? medicinesJson = prefs.getStringList(_key);

      if (medicinesJson == null || medicinesJson.isEmpty) {
        return [];
      }

      return medicinesJson.map((jsonStr) {
        Map<String, dynamic> json = jsonDecode(jsonStr);
        return Medicine.fromJson(json);
      }).toList();
    } catch (e) {
      print('İlaçları yükleme hatası: $e');
      return [];
    }
  }

  // Yeni ilaç ekle
  static Future<bool> addMedicine(Medicine medicine) async {
    try {
      List<Medicine> medicines = await loadMedicines();
      medicines.add(medicine);
      return await saveMedicines(medicines);
    } catch (e) {
      print('İlaç ekleme hatası: $e');
      return false;
    }
  }

  // Yeni ilaç ekle (ID otomatik üretilir)
  static Future<Medicine?> addMedicineWithAutoId({
    required String name,
    required String dosage,
    required int frequency,
    required List<TimeOfDay> times,
  }) async {
    try {
      int newId = await _getNextId();

      Medicine newMedicine = Medicine(
        id: newId.toString(),
        name: name,
        dosage: dosage,
        frequency: frequency,
        times: times,
        takenToday: List.generate(frequency, (index) => false),
      );

      bool success = await addMedicine(newMedicine);
      return success ? newMedicine : null;
    } catch (e) {
      print('İlaç ekleme hatası: $e');
      return null;
    }
  }

  // İlaç sil
  static Future<bool> deleteMedicine(String id) async {
    try {
      List<Medicine> medicines = await loadMedicines();
      medicines.removeWhere((medicine) => medicine.id == id);
      return await saveMedicines(medicines);
    } catch (e) {
      print('İlaç silme hatası: $e');
      return false;
    }
  }

  // İlaç güncelle
  static Future<bool> updateMedicine(Medicine updatedMedicine) async {
    try {
      List<Medicine> medicines = await loadMedicines();
      int index = medicines.indexWhere((m) => m.id == updatedMedicine.id);

      if (index != -1) {
        medicines[index] = updatedMedicine;
        return await saveMedicines(medicines);
      }
      return false;
    } catch (e) {
      print('İlaç güncelleme hatası: $e');
      return false;
    }
  }

  // Tüm verileri temizle
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_key);
    } catch (e) {
      print('Temizleme hatası: $e');
      return false;
    }
  }
}
