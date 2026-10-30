import 'package:flutter/material.dart';

/// Centralized color palette and dynamic token system for Tic Tac GO.
/// Supports both Neo-Blue Strategic Minimalist Light Theme and Dark Gaming Theme.
class AppColors {
  AppColors._();

  /// Global theme mode flag synchronized by [ThemeProvider]
  static bool isDarkMode = false;

  // ==========================================
  // DYNAMIC TOKENS (Switch based on isDarkMode)
  // ==========================================

  // Core Brand Tokens
  static Color get primary =>
      isDarkMode ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);
  static Color get primaryLight =>
      isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6);
  static Color get primaryDark =>
      isDarkMode ? const Color(0xFF1D4ED8) : const Color(0xFF1D4ED8);
  static Color get deepBlue =>
      isDarkMode ? const Color(0xFF1D4ED8) : const Color(0xFF1E40AF);
  static Color get deepBlueDark =>
      isDarkMode ? const Color(0xFF0F172A) : const Color(0xFF172554);

  // Background & Surfaces
  static Color get scaffoldBackground =>
      isDarkMode ? const Color(0xFF0B1220) : const Color(0xFFF9FAFB);
  static Color get surface =>
      isDarkMode ? const Color(0xFF111C2E) : const Color(0xFFFFFFFF);
  static Color get surfaceSecondary =>
      isDarkMode ? const Color(0xFF17243A) : const Color(0xFFF1F5F9);
  static Color get surfaceMuted =>
      isDarkMode ? const Color(0xFF1E2D47) : const Color(0xFFE2E8F0);
  static Color get border =>
      isDarkMode ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  static Color get borderDark =>
      isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

  // Board Specific Tokens
  static Color get boardSurface =>
      isDarkMode ? const Color(0xFF152238) : const Color(0xFFFFFFFF);
  static Color get boardBorder =>
      isDarkMode ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  static Color get boardGridLine =>
      isDarkMode ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  static Color get cellBackground =>
      isDarkMode ? const Color(0xFF17243A) : const Color(0xFFFFFFFF);
  static Color get cellHover =>
      isDarkMode ? const Color(0xFF1E2D47) : const Color(0xFFF8FAFC);

  // Typography & Neutrals
  static Color get textPrimary =>
      isDarkMode ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  static Color get textSecondary =>
      isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color get textMuted =>
      isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  // Button Bevels & Depth
  static Color get buttonBevel =>
      isDarkMode ? const Color(0xFF1D4ED8) : const Color(0xFF1E40AF);
  static Color get buttonWhiteBevel =>
      isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

  // Soft Ambient Glow Blobs
  static Color get bgGlowBlue =>
      isDarkMode ? const Color(0x2E3B82F6) : const Color(0x1F3B82F6);
  static Color get bgGlowCyan =>
      isDarkMode ? const Color(0x2606B6D4) : const Color(0x1A06B6D4);
  static Color get bgGlowRed =>
      isDarkMode ? const Color(0x26EF4444) : const Color(0x17EF4444);
  static Color get bgGlowAmber =>
      isDarkMode ? const Color(0x2E7F59E0) : const Color(0x21F59E0B);
  static Color get bgGlowPurple =>
      isDarkMode ? const Color(0x268B5CF6) : const Color(0x148B5CF6);

  // Shadows
  static Color get shadowSubtle =>
      isDarkMode ? const Color(0x33000000) : const Color(0x0F0F172A);
  static Color get shadowMedium =>
      isDarkMode ? const Color(0x4D000000) : const Color(0x1A0F172A);
  static Color get shadowStrong =>
      isDarkMode ? const Color(0x66000000) : const Color(0x330F172A);

  // ==========================================
  // CONSTANT TOKENS (Identity preserved in both)
  // ==========================================

  // Constant White Text
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textWhite70 = Color(0xB3FFFFFF);
  static const Color textWhite50 = Color(0x80FFFFFF);

  // Player X Tokens (Cobalt Royal Blue)
  static const Color xPrimary = Color(0xFF1D4ED8);
  static const Color xSecondary = Color(0xFF60A5FA);
  static const Color xBadge = Color(0xFF2563EB);

  // Player O Tokens (Coral Crimson Red)
  static const Color oPrimary = Color(0xFFB91C1C);
  static const Color oSecondary = Color(0xFFF87171);
  static const Color oBadge = Color(0xFFDC2626);

  // Highlights & Accents
  static const Color winHighlight = Color(0xFFF59E0B);
  static const Color winHighlightLight = Color(0xFFFDE68A);
  static const Color lastMoveMarker = Color(0xFF06B6D4);
  static const Color lastMoveRing = Color(0xFF67E8F9);
  static const Color iconGold = Color(0xFFF59E0B);

  // Match Outcome Status
  static const Color victory = Color(0xFF059669);
  static const Color victoryLight = Color(0xFF34D399);
  static const Color defeat = Color(0xFFDC2626);
  static const Color defeatLight = Color(0xFFF87171);
  static const Color draw = Color(0xFF94A3B8);
  static const Color drawLight = Color(0xFFCBD5E1);

  // Timer States
  static const Color timerNormal = Color(0xFF10B981);
  static const Color timerWarning = Color(0xFFF59E0B);
  static const Color timerCritical = Color(0xFFEF4444);

  // Glows
  static const Color glowPrimary = Color(0x332563EB);
  static const Color glowPrimaryStrong = Color(0x662563EB);
  static const Color glowX = Color(0x401D4ED8);
  static const Color glowO = Color(0x40DC2626);
  static const Color glowWin = Color(0x66F59E0B);
  static const Color glowLastMove = Color(0x4D06B6D4);

  // Functional Extras
  static const Color onlineIndicator = Color(0xFF22C55E);
  static const Color offlineIndicator = Color(0xFF94A3B8);
  static const Color transparent = Color(0x00000000);
  static const Color overlayDark = Color(0x66000000);
  static const Color overlayLight = Color(0x1AFFFFFF);
}
