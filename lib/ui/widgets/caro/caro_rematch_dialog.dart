import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../game/caro/caro_controller.dart';
import '../bouncing_game_button.dart';

class CaroRematchDialog extends StatefulWidget {
  final CaroController controller;
  final VoidCallback onRematch;
  final VoidCallback onGoHome;

  const CaroRematchDialog({
    super.key,
    required this.controller,
    required this.onRematch,
    required this.onGoHome,
  });

  @override
  State<CaroRematchDialog> createState() => _CaroRematchDialogState();
}

class _CaroRematchDialogState extends State<CaroRematchDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _scaleAnimation = CurvedAnimation(
      parent: _confettiController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDraw = widget.controller.winnerId == null;
    final bool iWon = widget.controller.winnerId == widget.controller.myUserId;

    final String title = isDraw
        ? "DRAW!"
        : (iWon ? "VICTORY!" : "DEFEAT!");

    final Color statusColor = isDraw
        ? AppColors.draw
        : (iWon ? AppColors.victory : AppColors.defeat);

    final IconData statusIcon = isDraw
        ? Icons.handshake_rounded
        : (iWon ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded);

    final int ratingChange = widget.controller.myRatingChange ?? 0;
    final String sign = ratingChange > 0 ? "+" : "";

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: AppColors.border, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouncing trophy/icon
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.12),
                    border: Border.all(color: statusColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.3),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 40),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),

              // Rating Change Tag
              if (!isDraw)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$sign$ratingChange ELO (${widget.controller.myRating ?? 1200})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Score Breakdown
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildScorePill('WINS', widget.controller.myWins, AppColors.primary),
                    Container(width: 1, height: 26, color: AppColors.border),
                    _buildScorePill('DRAWS', widget.controller.draws, AppColors.draw),
                    Container(width: 1, height: 26, color: AppColors.border),
                    _buildScorePill('LOSSES', widget.controller.opponentWins, AppColors.oPrimary),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Rematch button (3D tactile)
              BouncingGameButton(
                height: 52,
                backgroundColor: AppColors.primary,
                bevelColor: AppColors.buttonBevel,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onRematch();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.replay_rounded, color: AppColors.textWhite, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'PLAY AGAIN',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textWhite,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Home button
              BouncingGameButton(
                height: 50,
                backgroundColor: AppColors.surface,
                bevelColor: AppColors.buttonWhiteBevel,
                borderColor: AppColors.border,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onGoHome();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home_rounded, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'MAIN MENU',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScorePill(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
