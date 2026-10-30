import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized Haptic Feedback service for Tic Tac GO.
/// Respects the user's audio & feedback settings everywhere in the app.
class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  static const String prefKeyHaptic = 'settings_haptic_feedback';

  bool _isEnabled = true;
  bool get isEnabled => _isEnabled;

  /// Initialize and load saved haptic preference
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(prefKeyHaptic) ?? true;
    } catch (_) {
      _isEnabled = true;
    }
  }

  /// Update haptic preference and persist
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKeyHaptic, enabled);
    } catch (_) {}
    if (enabled) {
      mediumImpact();
    }
  }

  /// Light tactile feedback for button presses, tabs and interactive chips
  Future<void> lightImpact() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Crisp selection feedback when placing a stone on the board
  Future<void> selectionClick() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Medium tactile feedback for secondary actions, match loss, or alert dialogs
  Future<void> mediumImpact() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Strong tactile feedback for match victory
  Future<void> heavyImpact() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Distinct multi-pulse vibration when completing a 5-in-a-row winning streak
  /// Synchronized with the winning laser strike visual effect and sound
  Future<void> winningStreak() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 140));
      if (_isEnabled) {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {}
  }

  /// Balanced feedback for a drawn match
  Future<void> drawFeedback() async {
    if (!_isEnabled) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}
