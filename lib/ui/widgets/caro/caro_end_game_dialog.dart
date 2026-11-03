import 'package:flutter/material.dart';
import 'package:tic_tac_go/core/theme/app_colors.dart';
import 'package:tic_tac_go/game/caro/caro_controller.dart';
import 'package:tic_tac_go/game/caro/game_config.dart';
import '../bouncing_game_button.dart';

/// Interactive Center Dialog for Match Completion ("Game Over / Victory / Defeat / Draw").
/// Displays the winner outcome, match scores series, unlocked progression,
/// Master celebration banner, and actions (Next Level / Play Again / Home).
class CaroEndGameDialog extends StatelessWidget {
  final CaroController controller;
  final VoidCallback onPlayAgain;
  final VoidCallback onGoHome;
  final Function(GameLevel level)? onNextLevel;

  const CaroEndGameDialog({
    super.key,
    required this.controller,
    required this.onPlayAgain,
    required this.onGoHome,
    this.onNextLevel,
  });

  static Future<void> show({
    required BuildContext context,
    required CaroController controller,
    required VoidCallback onPlayAgain,
    required VoidCallback onGoHome,
    Function(GameLevel level)? onNextLevel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CaroEndGameDialog(
        controller: controller,
        onPlayAgain: onPlayAgain,
        onGoHome: onGoHome,
        onNextLevel: onNextLevel,
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
        ? (iAmWinner
            ? (controller.isMasterBeaten ? 'MASTER CONQUERED!' : 'VICTORY!')
            : 'DEFEAT')
        : 'MATCH DRAWN!';

    final IconData mainIcon = hasWinner
        ? (iAmWinner
            ? (controller.isMasterBeaten
                ? Icons.workspace_premium_rounded
                : Icons.emoji_events_rounded)
            : Icons.military_tech_rounded)
        : Icons.handshake_rounded;

    final bool hasNextLevel =
        iAmWinner && controller.newlyUnlockedLevel != null && onNextLevel != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
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
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Badge Icon with Glow
              Container(
                width: 64,
                height: 64,
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
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: controller.isMasterBeaten ? 19 : 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),

              // Subtitle with Level Name
              Text(
                controller.level != null
                    ? '${controller.level!.displayName} Rank • ${controller.rows}×${controller.cols} Grid'
                    : (controller.isVsBot
                        ? 'Tic Tac Go vs Bot AI'
                        : 'Tic Tac Go 2 Players'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),

              // Special Master Celebration Banner
              if (controller.isMasterBeaten) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.winHighlight.withValues(alpha: 0.22),
                        AppColors.primary.withValues(alpha: 0.22),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.winHighlight,
                      width: 1.5,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.winHighlight,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "MASTER! You beat the flawless AI!",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: AppColors.winHighlight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (hasNextLevel) ...[
                // Next Level Unlocked Banner
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.winHighlight.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.winHighlight,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_open_rounded,
                        color: AppColors.winHighlight,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Next level unlocked: ${controller.newlyUnlockedLevel!.displayName}!",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.winHighlight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Outcome Announcement Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                            ? "$winnerSymbol CONNECTED ${controller.winLen}! WINNER!"
                            : (controller.drawReason != null
                                ? "MATCH DRAWN! ${controller.drawReason}"
                                : "MATCH DRAWN!"),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          color: winnerSymbolColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Running Match Score Series
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                    Container(width: 1, height: 22, color: AppColors.border),
                    _buildScoreItem('DRAWS', controller.draws, AppColors.draw),
                    Container(width: 1, height: 22, color: AppColors.border),
                    _buildScoreItem(
                      controller.isVsBot ? 'BOT (O)' : 'P2 (O)',
                      controller.opponentWins,
                      AppColors.oPrimary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              Text(
                'Total moves: ${controller.moveCount}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              if (hasNextLevel) ...[
                BouncingGameButton(
                  height: 42,
                  backgroundColor: AppColors.winHighlight,
                  bevelColor: AppColors.iconGold,
                  borderColor: AppColors.winHighlight,
                  onPressed: () => onNextLevel!(controller.newlyUnlockedLevel!),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_forward_rounded,
                          color: AppColors.textWhite, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Next Level',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              Row(
                children: [
                  Expanded(
                    child: BouncingGameButton(
                      height: 42,
                      backgroundColor: hasNextLevel
                          ? AppColors.surfaceSecondary
                          : AppColors.primary,
                      bevelColor: hasNextLevel
                          ? AppColors.borderDark
                          : AppColors.primaryDark,
                      borderColor: hasNextLevel
                          ? AppColors.border
                          : AppColors.primaryDark,
                      onPressed: onPlayAgain,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: hasNextLevel
                                ? AppColors.textPrimary
                                : AppColors.textWhite,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Play Again',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: hasNextLevel
                                  ? AppColors.textPrimary
                                  : AppColors.textWhite,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BouncingGameButton(
                      height: 42,
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
                              fontSize: 12,
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
    ),
  );
  }

  Widget _buildScoreItem(String label, int score, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          score.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
