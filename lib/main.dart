import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:tic_tac_go/core/theme/app_colors.dart';
import 'package:tic_tac_go/core/theme/app_theme.dart';
import 'package:tic_tac_go/core/theme/theme_provider.dart';
import 'package:tic_tac_go/services/audio_service.dart';
import 'package:tic_tac_go/services/haptic_service.dart';
import 'package:tic_tac_go/services/local_storage_service.dart';
import 'package:tic_tac_go/ui/screens/intro_video_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Graceful offline fallback
  }

  await HapticService.instance.init();
  await AudioService.instance.init();

  final isDark = await LocalStorageService.isDarkMode();
  final themeProvider = ThemeProvider(initialDarkMode: isDark);

  runApp(
    ChangeNotifierProvider<ThemeProvider>.value(
      value: themeProvider,
      child: const CaroApp(),
    ),
  );
}

class CaroApp extends StatelessWidget {
  const CaroApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeProvider? provider;
    try {
      provider = context.watch<ThemeProvider?>();
    } catch (_) {}

    final bool isDark = provider?.isDarkMode ?? AppColors.isDarkMode;

    return MaterialApp(
      title: 'Tic Tac Go',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const IntroVideoScreen(),
    );
  }
}
