import 'package:flutter/material.dart';
import 'package:tic_tac_go/game/caro/caro_controller.dart';
import '../../../core/theme/app_colors.dart';

/// Displays information for both players (without animation).
class CaroPlayersInfo extends StatefulWidget {
  final CaroController controller;

  const CaroPlayersInfo({super.key, required this.controller});

  @override
  State<CaroPlayersInfo> createState() => _CaroPlayersInfoState();
}

class _CaroPlayersInfoState extends State<CaroPlayersInfo> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryLight, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: AppColors.draw)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Player X.
          _PlayerCard(
            symbol: "X",
            username: widget.controller.mySymbol == "X"
                ? widget.controller.myUsername
                : widget.controller.opponentUsername,
            color: AppColors.primaryLight,
            isMe: widget.controller.mySymbol == "X",
            isActive:
                widget.controller.currentTurn == "X" &&
                !widget.controller.isFinished,
          ),

          // Static VS divider.
          Container(
            width: 2,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.5),
                  AppColors.primary.withValues(alpha: 0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Player O.
          _PlayerCard(
            symbol: "O",
            username: widget.controller.mySymbol == "O"
                ? widget.controller.myUsername
                : widget.controller.opponentUsername,
            color: AppColors.defeat,
            isMe: widget.controller.mySymbol == "O",
            isActive:
                widget.controller.currentTurn == "O" &&
                !widget.controller.isFinished,
          ),
        ],
      ),
    );
  }
}

/// Displays information for one player (without animation).
class _PlayerCard extends StatelessWidget {
  final String symbol;
  final String? username;
  final Color color;
  final bool isMe;
  final bool isActive;

  const _PlayerCard({
    required this.symbol,
    this.username,
    required this.color,
    required this.isMe,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : AppColors.textWhite.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color.withValues(alpha: 0.8) : AppColors.draw,
          width: isActive ? 3 : 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.05),
                  blurRadius: 4,
                ),
              ],
      ),
      child: Row(
        children: [
          // Symbol (without animation).
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: isActive ? 10 : 4,
                  spreadRadius: isActive ? 1 : 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textWhite,
                  shadows: [Shadow(color: AppColors.textMuted, blurRadius: 3)],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    username ?? (isMe ? "You" : "Opponent"),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.draw,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.person, size: 14, color: color),
                  ],
                ],
              ),
              if (isActive)
                Text(
                  "🎯 Playing",
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
