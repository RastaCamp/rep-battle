import 'package:flutter/material.dart';

class AppTheme {
  static const Color arenaBlack = Color(0xFF0A0A0C);
  static const Color arenaRed = Color(0xFFE10600);
  static const Color arenaWhite = Color(0xFFF5F5F5);
  static const Color arenaGray = Color(0xFF1C1C22);

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: arenaBlack,
      colorScheme: const ColorScheme.dark(
        primary: arenaRed,
        secondary: arenaWhite,
        surface: arenaGray,
      ),
      fontFamily: 'Segoe UI',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: arenaWhite,
          letterSpacing: 2,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: arenaWhite,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: arenaWhite),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: arenaWhite,
          letterSpacing: 1.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: arenaRed,
          foregroundColor: arenaWhite,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 8,
        ),
      ),
    );
  }

  static BoxDecoration glowBorder(Color color) => BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.8), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      );
}
