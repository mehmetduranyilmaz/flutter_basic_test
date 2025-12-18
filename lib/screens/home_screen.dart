import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/medicine_storage.dart';
import '../services/notification_service.dart';
import '../screens/add_medicine_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Medicine> medicines = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  // İlaçları yükle
  Future<void> _loadMedicines() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Medicine> loadedMedicines = await MedicineStorage.loadMedicines();
      setState(() {
        medicines = loadedMedicines;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('İlaçlar yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // İlaç sil
  Future<void> _deleteMedicine(String id) async {
    bool success = await MedicineStorage.deleteMedicine(id);
    if (success) {
      // İlgili bildirimleri iptal et
      await _cancelMedicineNotifications(id);

      _loadMedicines(); // Listeyi yenile
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İlaç ve bildirimleri silindi'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // İlaç bildirimlerini iptal et
  Future<void> _cancelMedicineNotifications(String medicineId) async {
    final notificationService = NotificationService();
    final medicine = medicines.firstWhere((m) => m.id == medicineId);
    final baseId = int.parse(medicineId);

    // Bu ilaca ait tüm bildirimleri iptal et
    for (int i = 0; i < medicine.times.length; i++) {
      final notificationId = (baseId * 100) + i;
      await notificationService.cancelNotification(notificationId);
      debugPrint('🗑️ Bildirim iptal edildi: $notificationId');
    }
  }

  // İlaç durumunu güncelle
  Future<void> _updateMedicineTaken(
      Medicine medicine, int index, bool taken) async {
    // Yeni takenToday listesi oluştur
    List<bool> newTakenToday = List.from(medicine.takenToday);
    newTakenToday[index] = taken;

    // Güncellenmiş ilaç oluştur
    Medicine updatedMedicine = Medicine(
      id: medicine.id,
      name: medicine.name,
      dosage: medicine.dosage,
      frequency: medicine.frequency,
      times: medicine.times,
      takenToday: newTakenToday,
    );

    // Kaydet
    bool success = await MedicineStorage.updateMedicine(updatedMedicine);
    if (success) {
      _loadMedicines(); // Listeyi yenile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlaç Takip'),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : medicines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medication, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz ilaç eklenmemiş',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    Medicine medicine = medicines[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          Icons.medication,
                          color: Colors.indigo[600],
                          size: 32,
                        ),
                        title: Text(
                          medicine.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          '${medicine.dosage} - ${medicine.frequency}x/gün',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteMedicine(medicine.id),
                        ),
                        onTap: () {
                          // Detay sayfasına git veya checkbox göster
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMedicineScreen(
                onAdd: _loadMedicines, // Ekleme sonrası yenile
              ),
            ),
          );
        },
        backgroundColor: Colors.indigo[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
