import 'package:flutter/material.dart';
import 'package:tic_tac_go/game/caro/caro_controller.dart';
import '../../../core/theme/app_colors.dart';

/// Animated game status widget.
class CaroGameStatus extends StatefulWidget {
  final CaroController controller;

  const CaroGameStatus({super.key, required this.controller});

  @override
  State<CaroGameStatus> createState() => _CaroGameStatusState();
}

class _CaroGameStatusState extends State<CaroGameStatus>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String statusText;
    List<Color> gradientColors;
    IconData statusIcon;
    bool shouldPulse = false;

    if (!widget.controller.isConnected) {
      statusText = "🔌 Connecting...";
      gradientColors = [AppColors.winHighlight, AppColors.winHighlight];
      statusIcon = Icons.sync;
      shouldPulse = true;
    } else if (widget.controller.mySymbol == null) {
      statusText = "⏳ Waiting for opponent...";
      gradientColors = [AppColors.primaryLight, AppColors.primaryLight];
      statusIcon = Icons.hourglass_empty;
      shouldPulse = true;
    } else if (widget.controller.isFinished) {
      if (widget.controller.winnerId != null) {
        statusText = "🏆 Match over!";
        gradientColors = [AppColors.victory, AppColors.victory];
        statusIcon = Icons.emoji_events;
      } else {
        statusText = "🤝 Draw!";
        gradientColors = [AppColors.draw, AppColors.draw];
        statusIcon = Icons.handshake;
      }
    } else {
      final isMyTurn =
          widget.controller.currentTurn == widget.controller.mySymbol;
      if (isMyTurn) {
        final myName = widget.controller.myUsername ?? "You";
        statusText = "🎯 $myName's turn (${widget.controller.mySymbol})";
        gradientColors = [AppColors.victory, AppColors.primaryLight];
        statusIcon = Icons.touch_app;
        shouldPulse = true;
      } else {
        final opponentName = widget.controller.opponentUsername ?? "Opponent";
        statusText = "⏳ Waiting for $opponentName (${widget.controller.currentTurn})";
        gradientColors = [AppColors.winHighlight, AppColors.winHighlight];
        statusIcon = Icons.hourglass_empty;
      }
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: shouldPulse ? _pulseAnimation.value : 1.0,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Shimmer effect while waiting.
                if (shouldPulse)
                  Positioned.fill(
                    child: ClipRect(
                      child: Transform.translate(
                        offset: Offset(
                          _shimmerAnimation.value *
                              MediaQuery.of(context).size.width,
                          0,
                        ),
                        child: Container(
                          width: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.transparent,
                                AppColors.textWhite.withValues(alpha: 0.2),
                                AppColors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Main content.
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: shouldPulse
                              ? _animationController.value * 2 * 3.14159
                              : 0,
                          child: Opacity(
                            opacity: value,
                            child: Icon(
                              statusIcon,
                              color: AppColors.textWhite,
                              size: 24,
                              shadows: [
                                Shadow(
                                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textWhite,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: AppColors.textMuted,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
