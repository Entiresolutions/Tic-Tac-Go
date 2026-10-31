import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/// Centralized Haptic Feedback service for Tic Tac GO.
/// Uses the hardware vibrator via the vibration package with seamless fallback
/// to system HapticFeedback. Respects the user's settings everywhere.
class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  static const String prefKeyHaptic = 'settings_haptic_feedback';

  bool _isEnabled = true;
  bool _hasCustomVibrator = false;
  bool _hasPatternVibrator = false;
  bool _initialized = false;

  bool get isEnabled => _isEnabled;

  /// Initialize and load saved haptic preference and hardware capabilities
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(prefKeyHaptic) ?? true;
    } catch (_) {
      _isEnabled = true;
    }

    try {
      final hasVib = await Vibration.hasVibrator();
      _hasCustomVibrator = hasVib;
      if (_hasCustomVibrator) {
        final hasPattern = await Vibration.hasCustomVibrationsSupport();
        _hasPatternVibrator = hasPattern;
      }
    } catch (_) {
      _hasCustomVibrator = false;
      _hasPatternVibrator = false;
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
      if (_hasCustomVibrator) {
        Vibration.vibrate(duration: 25, amplitude: 60);
      } else {
        await HapticFeedback.lightImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.lightImpact();
      } catch (_) {}
    }
  }

  /// Crisp selection feedback when placing a stone on the board
  Future<void> selectionClick() async {
    if (!_isEnabled) return;
    try {
      if (_hasCustomVibrator) {
        Vibration.vibrate(duration: 35, amplitude: 90);
      } else {
        await HapticFeedback.selectionClick();
      }
    } catch (_) {
      try {
        await HapticFeedback.selectionClick();
      } catch (_) {}
    }
  }

  /// Medium tactile feedback for secondary actions, match loss, or alert dialogs
  Future<void> mediumImpact() async {
    if (!_isEnabled) return;
    try {
      if (_hasCustomVibrator) {
        Vibration.vibrate(duration: 55, amplitude: 140);
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }
  }

  /// Strong tactile feedback for match victory
  Future<void> heavyImpact() async {
    if (!_isEnabled) return;
    try {
      if (_hasCustomVibrator) {
        Vibration.vibrate(duration: 100, amplitude: 220);
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }
  }

  /// Distinct multi-pulse vibration when completing a winning streak
  /// Synchronized with the winning laser strike visual effect and sound.
  Future<void> winningStreak() async {
    if (!_isEnabled) return;
    try {
      if (_hasPatternVibrator) {
        // Multi-pulse burst: wait 0ms, buzz 70ms, wait 50ms, buzz 110ms, wait 50ms, buzz 180ms
        Vibration.vibrate(
          pattern: [0, 70, 50, 110, 50, 180],
          intensities: [0, 130, 0, 190, 0, 255],
        );
      } else if (_hasCustomVibrator) {
        Vibration.vibrate(duration: 180, amplitude: 255);
      } else {
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        if (_isEnabled) await HapticFeedback.heavyImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }
  }

  /// Balanced feedback for a drawn match
  Future<void> drawFeedback() async {
    if (!_isEnabled) return;
    try {
      if (_hasCustomVibrator) {
        Vibration.vibrate(duration: 60, amplitude: 120);
      } else {
        await HapticFeedback.mediumImpact();
      }
    } catch (_) {
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
    }
  }
}
