import 'package:flutter/material.dart';

class AppTheme {
  // ─── COULEURS EXACTES DU CAHIER DES CHARGES ───
  static const Color darkBg = Color(0xFF001A12);       // Fond principal
  static const Color darkSecondary = Color(0xFF002319); // Fond secondaire
  static const Color darkCard = Color(0xFF03251C);     // Fond des cartes
  static const Color deepGreen = Color(0xFF06452F);    // Vert profond
  static const Color brightGreen = Color(0xFF00D978);  // Vert lumineux
  static const Color goldYellow = Color(0xFFFFD43B);   // Jaune doré
  static const Color textWhite = Color(0xFFFFFFFF);    // Texte principal
  static const Color textGrey = Color(0xFFB7C6BF);     // Texte secondaire
  static const Color borderGreen = Color(0xFF14543D);  // Bordures

  // Alias pour éviter de tout casser dans les anciens fichiers
  static const Color yellow = goldYellow;
  static const Color green = brightGreen;
  static const Color blue = darkBg; // On remplace l'ancien bleu par le fond sombre

  // ─── DÉGRADÉS ───
  static const LinearGradient gradient = LinearGradient(
    colors: [deepGreen, darkBg],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient storyGradient = LinearGradient(
    colors: [goldYellow, brightGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [brightGreen, Color(0xFF00B862)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── THÈME GLOBAL ───
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: goldYellow,
        secondary: brightGreen,
        surface: darkCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: textWhite,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: textWhite),
        bodySmall: TextStyle(color: textGrey),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brightGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brightGreen,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textGrey),
        labelStyle: const TextStyle(color: textGrey),
      ),
    );
  }
}