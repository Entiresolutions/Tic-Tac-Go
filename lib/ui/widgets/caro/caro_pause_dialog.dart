import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../game/caro/caro_controller.dart';
import '../bouncing_game_button.dart';

class CaroPauseDialog {
  static void show({
    required BuildContext context,
    required CaroController controller,
    required VoidCallback onResume,
    required VoidCallback onRestart,
    required VoidCallback onLeave,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.border, width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.winHighlight.withValues(alpha: 0.12),
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
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'GAME PAUSED',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                controller.isVsBot ? 'Caro vs Bot AI' : 'Caro 2 Players',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Scores pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildScoreItem(
                        'YOU (X)', controller.myWins, AppColors.primary),
                    Container(width: 1, height: 24, color: AppColors.border),
                    _buildScoreItem('DRAWS', controller.draws, AppColors.draw),
                    Container(width: 1, height: 24, color: AppColors.border),
                    _buildScoreItem(
                      controller.isVsBot ? 'BOT (O)' : 'P2 (O)',
                      controller.opponentWins,
                      AppColors.oPrimary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Resume Button (Primary 3D)
              BouncingGameButton(
                height: 48,
                backgroundColor: AppColors.primary,
                bevelColor: AppColors.buttonBevel,
                extraGlow: const [
                  BoxShadow(
                    color: AppColors.glowPrimary,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
                onPressed: () {
                  Navigator.pop(context);
                  onResume();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.textWhite,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'RESUME',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textWhite,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Restart Button
              BouncingGameButton(
                height: 44,
                backgroundColor: AppColors.surface,
                bevelColor: AppColors.buttonWhiteBevel,
                borderColor: AppColors.border,
                onPressed: () {
                  Navigator.pop(context);
                  onRestart();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Restart Match',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Leave Button
              BouncingGameButton(
                height: 44,
                backgroundColor: AppColors.surface,
                bevelColor: AppColors.buttonWhiteBevel,
                borderColor: AppColors.border,
                onPressed: () {
                  Navigator.pop(context);
                  onLeave();
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.exit_to_app_rounded,
                      color: AppColors.defeat,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Leave Game',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.defeat,
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

  static Widget _buildScoreItem(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}
