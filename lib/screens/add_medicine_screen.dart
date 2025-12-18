import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/medicine_storage.dart';
import '../services/notification_service.dart';

class AddMedicineScreen extends StatefulWidget {
  final Function()? onAdd; // Artık Medicine göndermiyoruz, sadece bildirim

  const AddMedicineScreen({Key? key, this.onAdd}) : super(key: key);

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  int frequency = 1;
  List<TimeOfDay> times = [const TimeOfDay(hour: 8, minute: 0)];
  bool _isSaving = false; // Loading durumu için

  @override
  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        title: const Text('Yeni İlaç Ekle'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.grey[800],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputField('İlaç Adı', 'Örn: Aspirin', nameController),
                const SizedBox(height: 16),
                _buildInputField('Doz', 'Örn: 100mg', dosageController),
                const SizedBox(height: 16),
                _buildFrequencySelector(),
                const SizedBox(height: 16),
                _buildTimesList(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveMedicine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[600],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'İlacı Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.indigo[600]!, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Günde Kaç Kez?',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: frequency,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.indigo[600]!, width: 2),
            ),
          ),
          items: [1, 2, 3, 4, 5].map((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text('$value kez'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              frequency = value!;
              if (times.length < frequency) {
                while (times.length < frequency) {
                  int hour = 8 + times.length * 4;
                  if (hour >= 24) hour = hour - 24;
                  times.add(TimeOfDay(hour: hour, minute: 0));
                }
              } else if (times.length > frequency) {
                times = times.sublist(0, frequency);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildTimesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kullanım Saatleri',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(times.length, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () async {
                TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: times[index],
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Colors.indigo[600]!,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() {
                    times[index] = picked;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.indigo[600]),
                        const SizedBox(width: 12),
                        Text(
                          times[index].format(context),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${index + 1}. Doz',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _saveMedicine() async {
    // Validasyon
    if (nameController.text.trim().isEmpty) {
      _showErrorDialog('İlaç adını giriniz');
      return;
    }

    if (dosageController.text.trim().isEmpty) {
      _showErrorDialog('Doz bilgisini giriniz');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Otomatik ID ile yeni ilaç oluştur
      Medicine? newMedicine = await MedicineStorage.addMedicineWithAutoId(
        name: nameController.text.trim(),
        dosage: dosageController.text.trim(),
        frequency: frequency,
        times: times,
      );

      if (newMedicine != null) {
        // Bildirimleri kur
        await _scheduleNotifications(newMedicine);

        // Ana ekranı bilgilendir (refresh için)
        if (widget.onAdd != null) {
          widget.onAdd!();
        }

        // Başarı mesajı göster
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${newMedicine.name} başarıyla eklendi ve bildirimler kuruldu!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Ekranı kapat
          Navigator.pop(context);
        }
      } else {
        throw Exception('Kaydetme başarısız');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('İlaç kaydedilirken bir hata oluştu: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Bildirimleri zamanla
  Future<void> _scheduleNotifications(Medicine medicine) async {
    final notificationService = NotificationService();
    final baseId = int.parse(medicine.id);

    // Her saat için bildirim kur
    for (int i = 0; i < medicine.times.length; i++) {
      final time = medicine.times[i];

      // Bildirim ID'si: baseId * 100 + i (çakışma önleme)
      final notificationId = (baseId * 100) + i;

      await notificationService.scheduleDailyNotification(
        id: notificationId,
        title: '💊 İlaç Zamanı!',
        body: '${medicine.name} (${medicine.dosage}) - ${i + 1}. doz',
        time: time,
      );

      debugPrint(
          '✅ Bildirim kuruldu: ${medicine.name} - ${time.format(context)} (ID: $notificationId)');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
