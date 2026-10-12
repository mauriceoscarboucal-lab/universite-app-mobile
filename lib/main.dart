import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const UniversiteApp());
}

class UniversiteApp extends StatelessWidget {
  const UniversiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Université App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E40AF)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}