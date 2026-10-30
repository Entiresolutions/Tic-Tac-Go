import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Interactive game cell with dynamic symbol font scaling, 3D flip, win glow,
/// and last-move pulsing marker.
class CaroCell extends StatefulWidget {
  final int x;
  final int y;
  final String value;
  final VoidCallback onTap;
  final bool isWinningCell;
  final bool isLastMove;
  final double cellSize;

  const CaroCell({
    super.key,
    required this.x,
    required this.y,
    required this.value,
    required this.onTap,
    this.isWinningCell = false,
    this.isLastMove = false,
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
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isWinningCell) {
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
    if (widget.isWinningCell != oldWidget.isWinningCell) {
      if (widget.isWinningCell) {
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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_flipAnimation, _pulseAnimation]),
          builder: (context, child) {
            final double winScale =
                widget.isWinningCell ? _pulseAnimation.value : 1.0;

            return Transform.scale(
              scale: winScale,
              child: Container(
                margin: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: widget.isWinningCell
                      ? symbolColor.withValues(alpha: 0.14)
                      : (_isHovered && widget.value.isEmpty
                          ? AppColors.cellHover
                          : AppColors.cellBackground),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.isWinningCell
                        ? symbolColor
                        : (widget.isLastMove
                            ? AppColors.lastMoveMarker
                            : (_isHovered
                                ? AppColors.primaryLight
                                : AppColors.boardBorder)),
                    width: widget.isWinningCell
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
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);

        final isBackVisible = angle > math.pi / 2;

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: isBackVisible
              ? Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: _buildSymbolText(symbolColor),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildSymbolText(Color symbolColor) {
    // Responsive font scaling derived from cell size (approx 54% of cell size)
    final double fontSize = (widget.cellSize * 0.54).clamp(16.0, 36.0);

    return Text(
      widget.value,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: symbolColor,
        fontWeight: FontWeight.w900,
        fontSize: fontSize,
        shadows: [
          Shadow(
            color: symbolColor.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }
}
