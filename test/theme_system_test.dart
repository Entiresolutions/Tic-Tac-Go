import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tic_tac_go/core/theme/app_colors.dart';
import 'package:tic_tac_go/core/theme/app_theme.dart';
import 'package:tic_tac_go/core/theme/theme_provider.dart';
import 'package:tic_tac_go/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Theme System & Provider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        LocalStorageService.keyIsDarkMode: false,
      });
      LocalStorageService.resetPrefsForTesting();
      AppColors.isDarkMode = false;
    });

    test('Initializes with Light Mode default', () async {
      final provider = ThemeProvider();
      await provider.init();

      expect(provider.isDarkMode, isFalse);
      expect(provider.themeMode, equals(ThemeMode.light));
      expect(AppColors.isDarkMode, isFalse);

      // Verify Light mode color tokens
      expect(AppColors.scaffoldBackground, equals(const Color(0xFFF9FAFB)));
      expect(AppColors.surface, equals(const Color(0xFFFFFFFF)));
      expect(AppColors.primary, equals(const Color(0xFF2563EB)));
      expect(AppColors.border, equals(const Color(0xFFE5E7EB)));
    });

    test('Switches cleanly to Dark Mode and updates AppColors dynamically', () async {
      final provider = ThemeProvider();
      await provider.init();

      await provider.setDarkMode(true);

      expect(provider.isDarkMode, isTrue);
      expect(provider.themeMode, equals(ThemeMode.dark));
      expect(AppColors.isDarkMode, isTrue);

      // Verify Dark mode color tokens
      expect(AppColors.scaffoldBackground, equals(const Color(0xFF0B1220)));
      expect(AppColors.surface, equals(const Color(0xFF111C2E)));
      expect(AppColors.boardSurface, equals(const Color(0xFF152238)));
      expect(AppColors.primary, equals(const Color(0xFF3B82F6)));
      expect(AppColors.border, equals(const Color(0xFF334155)));
      expect(AppColors.textPrimary, equals(const Color(0xFFF8FAFC)));
      expect(AppColors.textSecondary, equals(const Color(0xFF94A3B8)));

      // Verify persistent storage updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(LocalStorageService.keyIsDarkMode), isTrue);
    });

    test('Identity and outcome tokens remain consistent across themes', () async {
      final provider = ThemeProvider();
      await provider.init();

      // Light mode check
      expect(AppColors.xPrimary, equals(const Color(0xFF1D4ED8)));
      expect(AppColors.oPrimary, equals(const Color(0xFFB91C1C)));
      expect(AppColors.winHighlight, equals(const Color(0xFFF59E0B)));
      expect(AppColors.victory, equals(const Color(0xFF059669)));
      expect(AppColors.defeat, equals(const Color(0xFFDC2626)));
      expect(AppColors.draw, equals(const Color(0xFF94A3B8)));

      // Switch to Dark mode
      await provider.setDarkMode(true);

      expect(AppColors.xPrimary, equals(const Color(0xFF1D4ED8)));
      expect(AppColors.oPrimary, equals(const Color(0xFFB91C1C)));
      expect(AppColors.winHighlight, equals(const Color(0xFFF59E0B)));
      expect(AppColors.victory, equals(const Color(0xFF059669)));
      expect(AppColors.defeat, equals(const Color(0xFFDC2626)));
      expect(AppColors.draw, equals(const Color(0xFF94A3B8)));
    });

    test('AppTheme light and dark ThemeData configurations are valid', () {
      final light = AppTheme.lightTheme;
      expect(light.brightness, equals(Brightness.light));
      expect(light.useMaterial3, isTrue);

      final dark = AppTheme.darkTheme;
      expect(dark.brightness, equals(Brightness.dark));
      expect(dark.useMaterial3, isTrue);
    });

    testWidgets('Interactive Theme Consumer reacts dynamically to changes', (tester) async {
      final themeProvider = ThemeProvider();
      await themeProvider.init();

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Consumer<ThemeProvider>(
            builder: (context, provider, child) {
              return MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: provider.themeMode,
                home: Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(provider.isDarkMode ? 'Dark Active' : 'Light Active'),
                        Switch(
                          value: provider.isDarkMode,
                          onChanged: (val) => provider.setDarkMode(val),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Light Active'), findsOneWidget);
      expect(themeProvider.isDarkMode, isFalse);

      // Tap toggle
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(themeProvider.isDarkMode, isTrue);
      expect(find.text('Dark Active'), findsOneWidget);
      expect(AppColors.isDarkMode, isTrue);
    });
  });
}
