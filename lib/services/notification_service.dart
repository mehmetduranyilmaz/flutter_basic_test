import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void onNotificationTapped(NotificationResponse response) async {
  debugPrint('👆 Bildirim tıklandı: ${response.payload}');
  debugPrint('   Action ID: ${response.actionId}');

  if (response.payload == null || response.payload!.isEmpty) return;

  try {
    final payloadData = jsonDecode(response.payload!);
    final int id = payloadData['id'];
    final String title = payloadData['title'];
    final String body = payloadData['body'];
    final int hour = payloadData['hour'];
    final int minute = payloadData['minute'];

    final NotificationService notificationService = NotificationService();
    await notificationService.initialize();

    // 🔴 EKRANDAKİ bildirimi kapat
    await notificationService.cancelNotification(id);

    if (response.actionId == 'snooze_action') {
      debugPrint('⏰ Erteleme: 1 dk sonra');

      // ✅ YENİ ID (çok önemli)
      final snoozeId = id + 100000;

      await notificationService.scheduleSnoozeNotification(
        id: snoozeId,
        title: title,
        body: body,
        hour: hour,
        minute: minute,
      );
    }

    if (response.actionId == 'taken_action') {
      debugPrint('✅ İlaç alındı');

      await notificationService.showInstantNotification(
        id: Random().nextInt(999999),
        title: '✅ Harika!',
        body: 'İlacınızı aldınız. Yarın aynı saatte hatırlatılacak.',
      );

      await notificationService.scheduleDailyNotification(
        id: id,
        title: title,
        body: body,
        time: TimeOfDay(hour: hour, minute: minute),
      );
    }
  } catch (e) {
    debugPrint('❌ Bildirim işleme hatası: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: onNotificationTapped,
    );

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (!status.isGranted) return false;

      try {
        await Permission.scheduleExactAlarm.request();
      } catch (_) {}

      return true;
    }
    return false;
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'instant_channel',
      'Anında Bildirimler',
      importance: Importance.max,
      priority: Priority.high,
      autoCancel: true,
    );

    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final payload = jsonEncode({
      'id': id,
      'title': title,
      'body': body,
      'hour': time.hour,
      'minute': time.minute,
    });

    await _scheduleNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
      scheduledDate: scheduledDate,
    );
  }

  Future<void> scheduleSnoozeNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final snoozeTime =
        tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));

    final payload = jsonEncode({
      'id': id,
      'title': title,
      'body': body,
      'hour': hour,
      'minute': minute,
    });

    await _scheduleNotification(
      id: id,
      title: title,
      body: body,
      payload: payload,
      scheduledDate: snoozeTime,
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    required tz.TZDateTime scheduledDate,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medicine_channel',
      'İlaç Hatırlatmaları',
      importance: Importance.max,
      priority: Priority.high,
      autoCancel: true, // ✅ KRİTİK
      actions: [
        AndroidNotificationAction(
          'snooze_action',
          '⏰ Ertele (1 dk)',
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'taken_action',
          '✅ Aldım',
          cancelNotification: true,
        ),
      ],
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
