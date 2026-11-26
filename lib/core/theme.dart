import 'package:flutter/material.dart';

class UbColors {
  UbColors._();

  static const bg = Color(0xFF020617); // slate-950
  static const surface = Color(0xFF0F172A); // slate-900
  static const card = Color(0xFF1E293B); // slate-800
  static const border = Color(0xFF334155); // slate-700
  static const cyan = Color(0xFF22D3EE);
  static const cyanDark = Color(0xFF06B6D4);
  static const emerald = Color(0xFF10B981);
  static const amber = Color(0xFFF59E0B);
  static const rose = Color(0xFFF43F5E);
  static const purple = Color(0xFFA855F7);
  static const textPrimary = Color(0xFFF1F5F9);
  static const textMuted = Color(0xFF94A3B8);
}

ThemeData buildUbTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: UbColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: UbColors.cyan,
      secondary: UbColors.emerald,
      surface: UbColors.surface,
      error: UbColors.rose,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: UbColors.bg,
      foregroundColor: UbColors.textPrimary,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: UbColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: UbColors.card),
      ),
    ),
  );
}
