import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'caro/caro_splash_screen.dart';

/// Silent intro video screen shown on launch before the splash screen.
/// Plays assets/splah_before.mp4 once with zero volume on a pure white canvas.
/// Automatically transitions to CaroSplashScreen when completed or on tap.
class IntroVideoScreen extends StatefulWidget {
  const IntroVideoScreen({super.key});

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  late final VideoPlayerController _controller;
  bool _hasNavigated = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.asset('assets/splah_before.mp4');
    try {
      await _controller.initialize();
      await _controller.setVolume(0.0);
      await _controller.setLooping(false);

      if (!mounted) return;

      _controller.addListener(_videoListener);
      setState(() {
        _isInitialized = true;
      });
      await _controller.play();
    } catch (e) {
      debugPrint('Intro video initialization error: $e');
      if (mounted) {
        _navigateToSplash();
      }
    }
  }

  void _videoListener() {
    if (_hasNavigated || !mounted) return;
    if (_controller.value.isInitialized) {
      final position = _controller.value.position;
      final duration = _controller.value.duration;
      if (duration > Duration.zero && position >= duration) {
        _navigateToSplash();
      }
    }
  }

  void _navigateToSplash() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    try {
      _controller.removeListener(_videoListener);
      _controller.pause();
    } catch (_) {}

    // Restore default system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CaroSplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    try {
      _controller.removeListener(_videoListener);
      _controller.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _navigateToSplash,
          child: Center(
            child: _isInitialized && _controller.value.isInitialized
                ? Center(
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: _controller.value.size.width > 0
                            ? _controller.value.size.width
                            : MediaQuery.of(context).size.width,
                        height: _controller.value.size.height > 0
                            ? _controller.value.size.height
                            : MediaQuery.of(context).size.height,
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio > 0
                              ? _controller.value.aspectRatio
                              : 16 / 9,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
