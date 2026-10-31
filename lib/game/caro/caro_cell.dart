import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Interactive game cell with dynamic symbol font scaling, 3D flip, win glow,
/// hint pulse indicator, and last-move pulsing marker.
class CaroCell extends StatefulWidget {
  final int x;
  final int y;
  final String value;
  final VoidCallback onTap;
  final bool isWinningCell;
  final bool isLastMove;
  final bool isHintCell;
  final double cellSize;

  const CaroCell({
    super.key,
    required this.x,
    required this.y,
    required this.value,
    required this.onTap,
    this.isWinningCell = false,
    this.isLastMove = false,
    this.isHintCell = false,
    this.cellSize = 48.0,
  });

  @override
  State<CaroCell> createState() => _CaroCellState();
}

class _CaroCellState extends State<CaroCell> with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _pulseController;
  late Animation<double> _flipAnimation;
  late Animation<double> _pulseAnimation;

  bool _isHovered = false;
  String _previousValue = "";

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeOutBack,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isWinningCell || widget.isHintCell) {
      _pulseController.repeat(reverse: true);
    }

    if (widget.value.isNotEmpty) {
      _flipController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CaroCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _previousValue) {
      _previousValue = widget.value;
      if (widget.value.isNotEmpty) {
        _flipController.forward(from: 0.0);
      } else {
        _flipController.value = 0.0;
      }
    }
    final needsPulse = widget.isWinningCell || widget.isHintCell;
    final hadPulse = oldWidget.isWinningCell || oldWidget.isHintCell;
    if (needsPulse != hadPulse) {
      if (needsPulse) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isX = widget.value == 'X';
    final Color symbolColor = isX ? AppColors.xPrimary : AppColors.oPrimary;
    final bool isHint = widget.isHintCell && widget.value.isEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_flipAnimation, _pulseAnimation]),
          builder: (context, child) {
            final double cellScale =
                (widget.isWinningCell || isHint) ? _pulseAnimation.value : 1.0;

            return Transform.scale(
              scale: cellScale,
              child: Container(
                margin: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: widget.isWinningCell
                      ? symbolColor.withValues(alpha: 0.14)
                      : (isHint
                          ? AppColors.winHighlight.withValues(alpha: 0.20)
                          : (_isHovered && widget.value.isEmpty
                              ? AppColors.cellHover
                              : AppColors.cellBackground)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.isWinningCell
                        ? symbolColor
                        : (isHint
                            ? AppColors.winHighlight
                            : (widget.isLastMove
                                ? AppColors.lastMoveMarker
                                : (_isHovered
                                    ? AppColors.primaryLight
                                    : AppColors.boardBorder))),
                    width: (widget.isWinningCell || isHint)
                        ? 2.2
                        : (widget.isLastMove ? 2.0 : 1.2),
                  ),
                  boxShadow: [
                    if (widget.isWinningCell)
                      BoxShadow(
                        color: symbolColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    else if (isHint)
                      BoxShadow(
                        color: AppColors.winHighlight.withValues(alpha: 0.45),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    else if (widget.isLastMove)
                      BoxShadow(
                        color: AppColors.glowLastMove,
                        blurRadius: 6,
                        spreadRadius: 0.5,
                      )
                    else
                      BoxShadow(
                        color: AppColors.shadowSubtle,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Hint indicator when empty
                    if (isHint)
                      Icon(
                        Icons.lightbulb_rounded,
                        color: AppColors.winHighlight,
                        size: (widget.cellSize * 0.42).clamp(14.0, 32.0),
                      ),

                    // Last move small indicator ring in corner
                    if (widget.isLastMove && widget.value.isNotEmpty)
                      Positioned(
                        top: 3,
                        right: 3,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.lastMoveMarker,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.glowLastMove,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Centered flip symbol
                    if (widget.value.isNotEmpty)
                      _buildAnimatedSymbol(symbolColor),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedSymbol(Color symbolColor) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        final angle = _flipAnimation.value * math.pi;
        final bool showFront = _flipAnimation.value >= 0.5;

        // Auto-scale font based on dynamic cell dimensions
        final double symbolFontSize = (widget.cellSize * 0.56).clamp(16.0, 48.0);

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: showFront
              ? Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: Center(
                    child: Text(
                      widget.value,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: symbolFontSize,
                        fontWeight: FontWeight.w900,
                        color: symbolColor,
                        shadows: [
                          Shadow(
                            color: symbolColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}
