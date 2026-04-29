// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temiz Rotacılar',
      debugShowCheckedModeBanner:
          false, // Sağ üstteki kırmızı "Debug" yazısını gizler
      theme: ThemeData(
        primaryColor: Colors.green,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      // UYGULAMANIN İLK AÇILIŞ EKRANI: Doğrudan yeni tasarladığımız Login ekranından başlar
      home: const LoginScreen(),
    );
  }
}
