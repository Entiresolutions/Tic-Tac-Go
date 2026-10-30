import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import 'app_colors.dart';

/// Central state provider managing Dark Mode and Light Mode throughout Tic Tac GO.
/// Changes propagate immediately without requiring application restart and persist to local storage.
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider({bool initialDarkMode = false}) {
    _isDarkMode = initialDarkMode;
    AppColors.isDarkMode = initialDarkMode;
  }

  /// Initialize theme from local storage
  Future<void> init() async {
    _isDarkMode = await LocalStorageService.isDarkMode();
    AppColors.isDarkMode = _isDarkMode;
    notifyListeners();
  }

  /// Update theme mode and persist immediately
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode == isDark) return;
    _isDarkMode = isDark;
    AppColors.isDarkMode = isDark;
    notifyListeners();
    await LocalStorageService.setDarkMode(isDark);
  }

  /// Toggle between Dark Mode and Light Mode
  Future<void> toggleTheme() async {
    await setDarkMode(!_isDarkMode);
  }
}

