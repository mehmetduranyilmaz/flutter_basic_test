import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  // Flutter binding'i başlat
  WidgetsFlutterBinding.ensureInitialized();

  // Notification service'i başlat
  final notificationService = NotificationService();
  await notificationService.initialize();

  // İzinleri iste
  await notificationService.requestPermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'İlaç Takip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
