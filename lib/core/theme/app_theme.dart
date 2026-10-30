import 'package:flutter/material.dart';

/// Centralized ThemeData specifications for Tic Tac GO.
/// Supports both Neo-Blue Strategic Minimalist Light Theme and Dark Gaming Theme.
class AppTheme {
  AppTheme._();

  // ==========================================
  // LIGHT THEME SPECIFICATION
  // ==========================================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF2563EB),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF1E40AF),
        onSecondary: Color(0xFFFFFFFF),
        error: Color(0xFFDC2626),
        onError: Color(0xFFFFFFFF),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF0F172A),
        outline: Color(0xFFE5E7EB),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E7EB),
        thickness: 1,
      ),
    );
  }

  // ==========================================
  // DARK THEME SPECIFICATION
  // ==========================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF3B82F6),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF1D4ED8),
        onSecondary: Color(0xFFFFFFFF),
        error: Color(0xFFEF4444),
        onError: Color(0xFFFFFFFF),
        surface: Color(0xFF111C2E),
        onSurface: Color(0xFFF8FAFC),
        outline: Color(0xFF334155),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF111C2E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155), width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
        titleTextStyle: TextStyle(
          color: Color(0xFFF8FAFC),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF111C2E),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
      ),
    );
  }
}
