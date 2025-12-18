import 'package:flutter/material.dart';

class Medicine {
  final String id;
  final String name;
  final String dosage;
  final int frequency;
  final List<TimeOfDay> times;
  final List<bool> takenToday;

  Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.takenToday,
  });

  // JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': times.map((time) => {'hour': time.hour, 'minute': time.minute}).toList(),
      'takenToday': takenToday,
    };
  }

  // JSON'dan oluştur
  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      name: json['name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      times: (json['times'] as List)
          .map((time) => TimeOfDay(hour: time['hour'], minute: time['minute']))
          .toList(),
      takenToday: List<bool>.from(json['takenToday']),
    );
  }
}