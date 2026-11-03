import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tic_tac_go/core/theme/app_theme.dart';
import 'package:tic_tac_go/core/theme/theme_provider.dart';
import 'package:tic_tac_go/game/caro/caro_controller.dart';
import 'package:tic_tac_go/ui/screens/caro/caro_home_screen.dart';
import 'package:tic_tac_go/ui/screens/caro/caro_splash_screen.dart';
import 'package:tic_tac_go/ui/screens/caro/play/caro_playing_screen.dart';
import 'package:tic_tac_go/ui/screens/caro/history/match_history_screen.dart';
import 'package:tic_tac_go/ui/screens/caro/profile/settings_screen.dart';
import 'package:tic_tac_go/ui/widgets/caro/caro_tutorial_dialog.dart';
import 'package:tic_tac_go/ui/widgets/caro/caro_level_dialog.dart';

void main() {
  const List<Size> testSizes = [
    Size(320, 568), // Small device (iPhone SE 1st gen)
    Size(375, 667), // Classic mobile (iPhone SE 2nd/3rd gen)
    Size(360, 800), // Standard modern Android
    Size(412, 915), // Large flagship Android
    Size(800, 1280), // Tablet portrait
    Size(1280, 800), // Tablet landscape
  ];

  for (final size in testSizes) {
    group('Screen layout test at ${size.width}x${size.height}', () {
      testWidgets('CaroHomeScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CaroHomeScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(CaroHomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('CaroPlayingScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final controller = CaroController(
          matchId: 999,
          isOffline: true,
          isVsBot: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: ChangeNotifierProvider<CaroController>.value(
              value: controller,
              child: const CaroScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(CaroScreen), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Teardown the widget and drain pending periodic timers in FakeAsync
        await tester.pumpWidget(const SizedBox());
        controller.disconnect();
        await tester.pump(const Duration(seconds: 35));
      });

      testWidgets('SettingsScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('CaroTutorialDialog (All Slides) renders without overflow',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: CaroTutorialDialog(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(CaroTutorialDialog), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Advance to Slide 2 (Tactics & Defense: You vs Opponent chips)
        final nextFinder = find.text('Next');
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.tap(nextFinder);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          expect(tester.takeException(), isNull);
        }

        // Advance to Slide 3 (Hints, Undos & Turn Clock)
        if (nextFinder.evaluate().isNotEmpty) {
          await tester.tap(nextFinder);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('CaroLevelSelectDialog renders without overflow',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: CaroLevelSelectDialog(
                isVsBot: true,
                onSelectLevel: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(CaroLevelSelectDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('MatchHistoryScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MatchHistoryScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(MatchHistoryScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('CaroSplashScreen renders without overflow', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CaroSplashScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(CaroSplashScreen), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Advance through animation to avoid pending timers
        await tester.pump(const Duration(milliseconds: 5000));
        await tester.pump(const Duration(milliseconds: 500));
      });
    });
  }
}
