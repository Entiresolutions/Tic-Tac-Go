import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/audio_service.dart';
import '../../services/haptic_service.dart';
import 'caro_controller.dart';
import 'caro_cell.dart';
import 'winning_line_data.dart';

/// Responsive, tactile game board with custom beveled frame, ambient glow,
/// and animated strike line over winning symbol streaks.
class CaroBoard extends StatefulWidget {
  const CaroBoard({super.key});

  @override
  State<CaroBoard> createState() => _CaroBoardState();
}

class _CaroBoardState extends State<CaroBoard>
    with SingleTickerProviderStateMixin {
  late AnimationController _lineController;
  late Animation<double> _lineAnimation;
  WinningLineData? _lastWinningLine;

  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _lineAnimation = CurvedAnimation(
      parent: _lineController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CaroController>();

    // Animate winning strike line when a new winning line is formed
    if (controller.winningLine != null &&
        controller.winningLine!.positions.isNotEmpty) {
      if (_lastWinningLine != controller.winningLine) {
        _lastWinningLine = controller.winningLine;
        _lineController.forward(from: 0.0);
        AudioService.instance.playLaserStrike();
        HapticService.instance.winningStreak();
      }
    } else {
      if (_lastWinningLine != null) {
        _lastWinningLine = null;
        _lineController.reset();
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Compute maximum square dimension that fits comfortably in the available space
        final double maxBoardDim = mathMin(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        // Generous padding to prevent clipping of shadows
        final double boardSize = (maxBoardDim - 16.0).clamp(240.0, 600.0);
        final double cellSize = (boardSize - 16.0) / controller.cols;

        // Compute strike line start and end coordinates
        Offset? lineStart;
        Offset? lineEnd;
        Color winLineColor = AppColors.winHighlight;

        final winningLine = controller.winningLine;
        if (winningLine != null && winningLine.positions.isNotEmpty) {
          final positions = winningLine.positions;
          final firstPos = positions.first;
          final symbol = controller.board[firstPos.x][firstPos.y];
          // Use winning symbol's exact color
          winLineColor = (symbol == 'X') ? AppColors.xPrimary : AppColors.oPrimary;

          if (positions.length == 1) {
            final p = positions.first;
            final center = Offset(
              8.0 + (p.y + 0.5) * cellSize,
              8.0 + (p.x + 0.5) * cellSize,
            );
            lineStart = center;
            lineEnd = center;
          } else {
            // Find extreme endpoints with maximum distance
            Position p1 = positions.first;
            Position p2 = positions.last;
            double maxDistSq = -1;

            for (int i = 0; i < positions.length; i++) {
              for (int j = i + 1; j < positions.length; j++) {
                final dx = positions[i].y - positions[j].y;
                final dy = positions[i].x - positions[j].x;
                final distSq = (dx * dx + dy * dy).toDouble();
                if (distSq > maxDistSq) {
                  maxDistSq = distSq;
                  p1 = positions[i];
                  p2 = positions[j];
                }
              }
            }

            lineStart = Offset(
              8.0 + (p1.y + 0.5) * cellSize,
              8.0 + (p1.x + 0.5) * cellSize,
            );
            lineEnd = Offset(
              8.0 + (p2.y + 0.5) * cellSize,
              8.0 + (p2.x + 0.5) * cellSize,
            );

            // Extend line slightly past cell centers so it strikes cleanly through
            final delta = lineEnd - lineStart;
            if (delta.distance > 0) {
              final unit = delta / delta.distance;
              lineStart -= unit * (cellSize * 0.38);
              lineEnd += unit * (cellSize * 0.38);
            }
          }
        }

        return Center(
          child: Stack(
            children: [
              Container(
                width: boardSize,
                height: boardSize,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.boardSurface,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: AppColors.boardBorder, width: 2.0),
                  boxShadow: [
                    // Layered 3D board shadows
                    BoxShadow(
                      color: AppColors.shadowMedium,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.shadowSubtle,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.rows * controller.cols,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: controller.cols,
                  ),
                  itemBuilder: (context, index) {
                    final int x = index ~/ controller.cols;
                    final int y = index % controller.cols;
                    final bool isWinning =
                        controller.winningLine?.contains(x, y) ?? false;
                    final bool isLastMove =
                        controller.lastMoveRow == x && controller.lastMoveCol == y;

                    return CaroCell(
                      x: x,
                      y: y,
                      value: controller.board[x][y],
                      isWinningCell: isWinning,
                      isLastMove: isLastMove,
                      cellSize: cellSize,
                      onTap: () {
                        if (!controller.isFinished && !controller.isPaused) {
                          final bool canMove = (controller.isOffline &&
                                  !controller.isVsBot) ||
                              (controller.mySymbol == controller.currentTurn);
                          if (canMove && controller.board[x][y].isEmpty) {
                            HapticService.instance.selectionClick();
                            controller.sendMove(x, y);
                          }
                        }
                      },
                    );
                  },
                ),
              ),

              // Animated Strike-through line on winning streak
              if (lineStart != null && lineEnd != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _lineAnimation,
                      builder: (context, _) {
                        return CustomPaint(
                          size: Size(boardSize, boardSize),
                          painter: WinningStrikePainter(
                            start: lineStart!,
                            end: lineEnd!,
                            progress: _lineAnimation.value,
                            color: winLineColor,
                          ),
                        );
                      },
                    ),
                  ),
                ),

              if (controller.isPaused)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: AppColors.winHighlight, width: 2.0),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                              border: Border.all(
                                color: AppColors.winHighlight,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.glowWin,
                                  blurRadius: 16,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.pause_rounded,
                              color: AppColors.winHighlight,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'GAME PAUSED',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double mathMin(double a, double b) => a < b ? a : b;
}

/// Custom painter that draws a luminous, colored strike-through line over winning symbols
class WinningStrikePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final double progress;
  final Color color;

  WinningStrikePainter({
    required this.start,
    required this.end,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final currentEnd = Offset.lerp(start, end, progress)!;

    // 1. Ambient bloom / glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.40)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawLine(start, currentEnd, glowPaint);

    // 2. Middle vibrant stroke
    final middlePaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, currentEnd, middlePaint);

    // 3. Crisp foreground line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, currentEnd, linePaint);

    // 4. Specular core white highlight
    final corePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, currentEnd, corePaint);
  }

  @override
  bool shouldRepaint(WinningStrikePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.color != color;
  }
}
