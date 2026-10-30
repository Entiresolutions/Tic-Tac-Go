import 'package:flutter/material.dart';
import 'package:tic_tac_go/core/theme/app_colors.dart';
import 'package:tic_tac_go/game/caro/caro_controller.dart';
import '../bouncing_game_button.dart';

/// Interactive Center Dialog for Match Completion ("Game Over / Victory / Defeat / Draw").
/// Displays the winner outcome, match scores series, and actions (Play Again / Home).
class CaroEndGameDialog extends StatelessWidget {
  final CaroController controller;
  final VoidCallback onPlayAgain;
  final VoidCallback onGoHome;

  const CaroEndGameDialog({
    super.key,
    required this.controller,
    required this.onPlayAgain,
    required this.onGoHome,
  });

  static Future<void> show({
    required BuildContext context,
    required CaroController controller,
    required VoidCallback onPlayAgain,
    required VoidCallback onGoHome,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CaroEndGameDialog(
        controller: controller,
        onPlayAgain: onPlayAgain,
        onGoHome: onGoHome,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasWinner = controller.winnerId != null;
    final bool iAmWinner =
        hasWinner && controller.winnerId == controller.myUserId;

    // Determine winning symbol and color
    String winnerSymbol = '';
    if (controller.winningLine != null &&
        controller.winningLine!.positions.isNotEmpty) {
      final pos = controller.winningLine!.positions.first;
      winnerSymbol = controller.board[pos.x][pos.y];
    } else if (hasWinner) {
      winnerSymbol = iAmWinner ? 'X' : 'O';
    }

    final Color outcomeColor = hasWinner
        ? (iAmWinner ? AppColors.winHighlight : AppColors.defeat)
        : AppColors.draw;

    final Color winnerSymbolColor = winnerSymbol == 'X'
        ? AppColors.xPrimary
        : (winnerSymbol == 'O' ? AppColors.oPrimary : outcomeColor);

    final String title = hasWinner
        ? (iAmWinner ? 'VICTORY!' : 'DEFEAT')
        : 'MATCH DRAWN!';

    final IconData mainIcon = hasWinner
        ? (iAmWinner ? Icons.emoji_events_rounded : Icons.military_tech_rounded)
        : Icons.handshake_rounded;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 350),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: outcomeColor.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Icon with Glow
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: outcomeColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: outcomeColor.withValues(alpha: 0.35),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: outcomeColor.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  mainIcon,
                  color: outcomeColor,
                  size: 38,
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                controller.isVsBot
                    ? 'Tic Tac Go vs Bot AI'
                    : 'Tic Tac Go 2 Players',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Bottom-Wala Data Pill (Winner/Outcome Announcement)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: winnerSymbolColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: winnerSymbolColor.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasWinner
                          ? Icons.emoji_events_rounded
                          : Icons.handshake_rounded,
                      size: 16,
                      color: winnerSymbolColor,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        hasWinner
                            ? "$winnerSymbol CONNECTED 5! WINNER!"
                            : "MATCH DRAWN!",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: winnerSymbolColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Running Match Score Breakdown
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
              const SizedBox(height: 8),

              // Move count
              Text(
                'Total moves: ${controller.moveCount}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons: Play Again & Home
              Row(
                children: [
                  Expanded(
                    child: BouncingGameButton(
                      height: 44,
                      backgroundColor: AppColors.primary,
                      bevelColor: AppColors.primaryDark,
                      borderColor: AppColors.primaryDark,
                      onPressed: onPlayAgain,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: AppColors.textWhite,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Play Again',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BouncingGameButton(
                      height: 44,
                      backgroundColor: AppColors.surfaceSecondary,
                      bevelColor: AppColors.borderDark,
                      borderColor: AppColors.border,
                      onPressed: onGoHome,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_rounded,
                            color: AppColors.textPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Home',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, int score, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$score',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
