import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/local_storage_service.dart';
import 'caro_home_screen.dart';

/// Ultra-smooth, high-performance Splash Screen for "Tic Tac GO".
/// Strictly adheres to the "Neo-Blue Strategic Minimalist" design system.
/// Features an optimized 5×5 micro-board with 5 diagonal 'X's, all 20 other boxes
/// filled with 'O's in a diagonal card-flip wave, animated glowing strike line,
/// 5-second progress bar, and "POWERED BY ENTIRE SOLUTION" badge.
class CaroSplashScreen extends StatefulWidget {
  const CaroSplashScreen({super.key});

  @override
  State<CaroSplashScreen> createState() => _CaroSplashScreenState();
}

class _CaroSplashScreenState extends State<CaroSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  // Master animations
  late final Animation<double> _gridScaleAnim;
  late final Animation<double> _piecesWaveAnim;
  late final Animation<double> _winGlowAnim;
  late final Animation<double> _strikeLineAnim;
  late final Animation<double> _titleFadeAnim;
  late final Animation<Offset> _titleSlideAnim;
  late final Animation<double> _progressAnim;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    // 5-second splash duration
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    // 1. 0.0s – 0.8s: 5x5 Board scales in with elastic bounce
    _gridScaleAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.16, curve: Curves.easeOutBack),
    );

    // 2. 0.8s – 2.8s: Master linear wave driver for all 25 pieces
    _piecesWaveAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.16, 0.56, curve: Curves.linear),
    );

    // 3. 2.8s – 3.8s: 5 diagonal cells light up with Amber/Gold glow & strike line
    _winGlowAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.56, 0.76, curve: Curves.easeOut),
    );
    _strikeLineAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.56, 0.76, curve: Curves.easeOutCubic),
    );

    // 4. 2.2s – 4.0s: Title & pill badge fade and slide up
    _titleFadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.44, 0.78, curve: Curves.easeOut),
    );
    _titleSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.44, 0.78, curve: Curves.easeOutCubic),
      ),
    );

    // 5. 5-second footer progress indicator
    _progressAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.04, 0.98, curve: Curves.linear),
    );

    _animController.forward();
    _preloadStorageAndNavigate();
  }

  /// Initializes LocalStorageService concurrently with splash animation
  Future<void> _preloadStorageAndNavigate() async {
    final stopwatch = Stopwatch()..start();

    try {
      await Future.wait([
        LocalStorageService.getOrCreateProfile(),
        LocalStorageService.getMatches(),
      ]);
    } catch (e) {
      debugPrint('CaroSplashScreen: LocalStorageService preload note: $e');
    }

    // Ensure splash plays for the full 5.0s duration requested
    final elapsed = stopwatch.elapsedMilliseconds;
    if (elapsed < 5000) {
      await Future.delayed(Duration(milliseconds: 5000 - elapsed));
    }

    if (!mounted || _isDisposed) return;

    // Smooth Combined Fade + Subtle Scale transition (400ms)
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CaroHomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Stack(
        children: [
          // Background Gradient (Isolated in RepaintBoundary for 60fps performance)
          Positioned.fill(
            child: RepaintBoundary(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.scaffoldBackground,
                      AppColors.isDarkMode
                          ? const Color(0xFF111C2E)
                          : const Color(0xFFEFF6FF),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Ambient Radial Glow blobs
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgGlowBlue,
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bgGlowCyan,
              ),
            ),
          ),

          // Main Centerpiece Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),

                      // Animated 5×5 Micro-Board (All blank boxes filled with 'O')
                      _build5x5MicroBoard(),

                      const SizedBox(height: 28),

                      // Title & Subtitle Badge
                      _buildTitleAndBadge(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 5-Second Footer Progress Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: _buildFooterProgress(),
            ),
          ),
        ],
      ),
    );
  }

  /// Calculates individual cell flip progress (wave pattern across diagonal r + c)
  double _getCellFlipProgress(int r, int c, double masterWave) {
    if (masterWave <= 0.0) return 0.0;
    // Wave index from 0 to 8 (top-left to bottom-right)
    final int waveIndex = r + c;
    final double waveStart = waveIndex * 0.07; // staggered start
    final double raw = ((masterWave - waveStart) / 0.38).clamp(0.0, 1.0);
    return Curves.easeOutBack.transform(raw);
  }

  /// Centerpiece: Animated 5×5 Micro-Board with 5 diagonal 'X's and all other 20 boxes filled with 'O's
  Widget _build5x5MicroBoard() {
    const double boardDim = 196.0;
    const double padding = 8.0;
    const double gap = 4.0;
    const double cellDim = (boardDim - (padding * 2) - (gap * 4)) / 5; // 32.8dp

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          final double scale = _gridScaleAnim.value;
          if (scale <= 0.001) return const SizedBox(height: boardDim);

          final double wave = _piecesWaveAnim.value;
          final double winGlow = _winGlowAnim.value;
          final double strikeProgress = _strikeLineAnim.value;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: boardDim,
              height: boardDim,
              decoration: BoxDecoration(
                color: AppColors.boardSurface,
                borderRadius: BorderRadius.circular(22.0),
                border: Border.all(
                  color: AppColors.boardBorder,
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppColors.shadowSubtle,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 5×5 Grid (All 25 cells occupied: 5 diagonal X's, 20 O's)
                  Padding(
                    padding: const EdgeInsets.all(padding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (r) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(5, (c) {
                            final bool isWinningCell = (r == c);
                            final double flipProgress =
                                _getCellFlipProgress(r, c, wave);

                            return _buildCell(
                              cellDim: cellDim,
                              isWinning: isWinningCell,
                              winGlow: winGlow,
                              child: isWinningCell
                                  ? _buildFlippingPiece(
                                      progress: flipProgress,
                                      child: const _SymbolX(size: 18),
                                    )
                                  : _buildFlippingPiece(
                                      progress: flipProgress,
                                      child: const _SymbolO(size: 18),
                                    ),
                            );
                          }),
                        );
                      }),
                    ),
                  ),

                  // Animated glowing strike line over 5 winning diagonal X's
                  if (strikeProgress > 0.0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: const Size(boardDim, boardDim),
                          painter: _MicroBoardStrikePainter(
                            progress: strikeProgress,
                            start: const Offset(15.0, 15.0),
                            end: const Offset(boardDim - 15.0, boardDim - 15.0),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Micro-board individual cell
  Widget _buildCell({
    required double cellDim,
    required bool isWinning,
    required double winGlow,
    required Widget child,
  }) {
    final double glow = isWinning ? winGlow : 0.0;

    final Color bgColor = Color.lerp(
      AppColors.cellBackground,
      AppColors.winHighlight.withValues(alpha: 0.16),
      glow,
    )!;

    final Color borderColor = Color.lerp(
      AppColors.surfaceSecondary,
      AppColors.winHighlight,
      glow,
    )!;

    return Container(
      width: cellDim,
      height: cellDim,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9.0),
        border: Border.all(
          color: borderColor,
          width: isWinning ? (1.0 + (glow * 0.8)) : 1.0,
        ),
        boxShadow: glow > 0
            ? [
                BoxShadow(
                  color: const Color(0xFFF59E0B)
                      .withValues(alpha: 0.35 * glow),
                  blurRadius: 8 * glow,
                  spreadRadius: 1 * glow,
                ),
              ]
            : null,
      ),
      child: Center(child: child),
    );
  }

  /// Signature 3D Y-axis card flip animation
  Widget _buildFlippingPiece({
    required double progress,
    required Widget child,
  }) {
    if (progress <= 0.001) return const SizedBox.shrink();

    final double angle = (1.0 - progress) * (math.pi / 2);
    final double opacity = (progress * 2.0).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle),
        child: child,
      ),
    );
  }

  /// Title "Tic Tac GO" with blue gradient shader and "POWERED BY ENTIRE SOLUTION" pill badge
  Widget _buildTitleAndBadge() {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          return Opacity(
            opacity: _titleFadeAnim.value,
            child: SlideTransition(
              position: _titleSlideAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "Tic Tac GO" Gradient Title
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF1D4ED8), // Cobalt Royal Blue
                          Color(0xFF2563EB), // Primary
                          Color(0xFF60A5FA), // Light Accent
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: const Text(
                        'Tic Tac GO',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Sleek Pill Badge: "POWERED BY ENTIRE SOLUTION"
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.border,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowSubtle,
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'POWERED BY ENTIRE SOLUTION',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 5-second minimalist animated footer progress bar
  Widget _buildFooterProgress() {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          final double progress = _progressAnim.value;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Track & Fill bar
              Container(
                width: 120,
                height: 3.5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 120 * progress,
                    height: 3.5,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Subtle Status Tag
              Text(
                progress < 0.98 ? 'INITIALIZING ENGINE...' : 'READY',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Zero-asset custom painted 'X' with Cobalt Royal Blue Gradient
class _SymbolX extends StatelessWidget {
  final double size;
  const _SymbolX({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _XPainter(),
    );
  }
}

class _XPainter extends CustomPainter {
  const _XPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1D4ED8), // Cobalt Blue Dark
          Color(0xFF60A5FA), // Cobalt Blue Light
        ],
      ).createShader(rect)
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final double pad = size.width * 0.16;
    canvas.drawLine(
      Offset(pad, pad),
      Offset(size.width - pad, size.height - pad),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - pad, pad),
      Offset(pad, size.height - pad),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Zero-asset custom painted 'O' with Coral Crimson Red Gradient
class _SymbolO extends StatelessWidget {
  final double size;
  const _SymbolO({required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _OPainter(),
    );
  }
}

class _OPainter extends CustomPainter {
  const _OPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeW = size.width * 0.20;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFB91C1C), // Coral Crimson Dark
          Color(0xFFF87171), // Coral Crimson Light
        ],
      ).createShader(rect)
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeW - (size.width * 0.16)) / 2;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated glowing strike-through line over winning symbols on the micro-board
class _MicroBoardStrikePainter extends CustomPainter {
  final double progress;
  final Offset start;
  final Offset end;

  const _MicroBoardStrikePainter({
    required this.progress,
    required this.start,
    required this.end,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final currentEnd = Offset.lerp(start, end, progress)!;

    // 1. Ambient bloom in Glowing Amber/Gold
    final glowPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.45)
      ..strokeWidth = 11.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.drawLine(start, currentEnd, glowPaint);

    // 2. Main vivid strike line
    final linePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, currentEnd, linePaint);

    // 3. Specular core white highlight
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, currentEnd, corePaint);
  }

  @override
  bool shouldRepaint(_MicroBoardStrikePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.start != start ||
        oldDelegate.end != end;
  }
}
