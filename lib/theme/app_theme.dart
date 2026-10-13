import 'package:flutter/material.dart';

/// 🎨 THÈME OFFICIEL DE L'APPLICATION
class AppTheme {
  // ─── COULEURS PRINCIPALES ──────────────────
  static const Color blue = Color(0xFF2979FF);
  static const Color green = Color(0xFF00C853);
  static const Color yellow = Color(0xFFFFD600);

  // ─── COULEURS SECONDAIRES ──────────────────
  static const Color blueDark = Color(0xFF1565C0);
  static const Color blueLight = Color(0xFF4FC3F7);
  static const Color greenDark = Color(0xFF00A144);
  static const Color yellowDark = Color(0xFFFFC107);
  static const Color yellowOrange = Color(0xFFFFAB00);

  // ─── COULEURS NEUTRES ─────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1A1A1A);
  static const Color grey = Color(0xFF757575);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyBg = Color(0xFFF5F5F5);

  // ─── DÉGRADÉ PRINCIPAL (Bleu → Vert → Jaune) ───
  static const LinearGradient gradient = LinearGradient(
    colors: [blue, green, yellow],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── DÉGRADÉ POUR LES CERCLES DE STORIES ───
  static const LinearGradient storyGradient = LinearGradient(
    colors: [blue, green, yellow],
    stops: [0.0, 0.5, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── DÉGRADÉ POUR LES BOUTONS ──────────────
  static const LinearGradient buttonGradient = LinearGradient(
    colors: [blue, green],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ─── THÈME GLOBAL ──────────────────────────
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        primary: green,
        secondary: yellow,
      ),
      scaffoldBackgroundColor: white,
      appBarTheme: const AppBarTheme(
        backgroundColor: blue,
        foregroundColor: white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: green,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: green,
        foregroundColor: white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: green,
        unselectedItemColor: grey,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: green, width: 2),
        ),
      ),
    );
  }
}