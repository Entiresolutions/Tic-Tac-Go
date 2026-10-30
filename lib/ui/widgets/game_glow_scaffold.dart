import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable background wrapper providing subtle, soft ambient glow for a rich game feel.
class GameGlowScaffold extends StatelessWidget {
  final Widget child;
  final bool hasTopGlow;
  final bool hasBottomGlow;
  final Color? topGlowColor;
  final Color? bottomGlowColor;

  const GameGlowScaffold({
    super.key,
    required this.child,
    this.hasTopGlow = true,
    this.hasBottomGlow = true,
    this.topGlowColor,
    this.bottomGlowColor,
  });

  @override
  Widget build(BuildContext context) {
    final topColor = topGlowColor ?? AppColors.bgGlowBlue;
    final bottomColor = bottomGlowColor ?? AppColors.bgGlowCyan;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            hasTopGlow ? topColor : AppColors.scaffoldBackground,
            AppColors.scaffoldBackground,
            hasBottomGlow ? bottomColor : AppColors.scaffoldBackground,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: child,
    );
  }
}
