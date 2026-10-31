import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../game/caro/game_config.dart';
import '../../../services/audio_service.dart';
import '../../../services/haptic_service.dart';
import '../../../services/local_storage_service.dart';
import '../bouncing_game_button.dart';

/// Premium Level Select Dialog for both "PLAY WITH BOT" and "2 PLAYERS" modes.
/// Adheres strictly to the Neo-Blue Strategic Minimalist design system.
class CaroLevelSelectDialog extends StatefulWidget {
  final bool isVsBot;
  final Function(GameLevel level) onSelectLevel;

  const CaroLevelSelectDialog({
    super.key,
    required this.isVsBot,
    required this.onSelectLevel,
  });

  static Future<GameLevel?> show({
    required BuildContext context,
    required bool isVsBot,
    required Function(GameLevel level) onSelectLevel,
  }) {
    return showDialog<GameLevel>(
      context: context,
      barrierDismissible: true,
      builder: (_) => CaroLevelSelectDialog(
        isVsBot: isVsBot,
        onSelectLevel: onSelectLevel,
      ),
    );
  }

  @override
  State<CaroLevelSelectDialog> createState() => _CaroLevelSelectDialogState();
}

class _CaroLevelSelectDialogState extends State<CaroLevelSelectDialog> {
  GameLevel _selectedLevel = GameLevel.beginner;
  GameLevel _unlockedLevel = GameLevel.beginner;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgression();
  }

  Future<void> _loadProgression() async {
    if (widget.isVsBot) {
      final unlocked = await LocalStorageService.getBotUnlockedLevel();
      if (mounted) {
        setState(() {
          _unlockedLevel = unlocked;
          _selectedLevel = unlocked;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _selectedLevel = GameLevel.master;
          _isLoading = false;
        });
      }
    }
  }

  bool _isLevelLocked(GameLevel level) {
    if (!widget.isVsBot) return false;
    return level.index > _unlockedLevel.index;
  }

  void _onLevelTap(GameLevel level) {
    if (_isLevelLocked(level)) {
      HapticService.instance.mediumImpact();
      final prevLevel = GameLevel.values[level.index - 1];
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.draw, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Beat ${prevLevel.displayName} to unlock!',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surfaceSecondary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.border),
          ),
        ),
      );
      return;
    }

    HapticService.instance.selectionClick();
    AudioService.instance.playButtonClick();
    setState(() {
      _selectedLevel = level;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 680),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.glowPrimary,
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: _isLoading
              ? const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Icon(
                            widget.isVsBot
                                ? Icons.smart_toy_rounded
                                : Icons.people_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isVsBot ? 'CHOOSE BOT DIFFICULTY' : 'CHOOSE MATCH LEVEL',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.isVsBot
                                    ? 'Win matches to unlock higher ranks'
                                    : 'Select any grid size & win streak',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 22),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Scrollable list of 6 levels
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: GameLevel.values.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final level = GameLevel.values[index];
                          final isLocked = _isLevelLocked(level);
                          final isSelected = _selectedLevel == level && !isLocked;

                          return _buildLevelCard(level, isLocked, isSelected);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Start Game Button
                    BouncingGameButton(
                      height: 48,
                      backgroundColor: AppColors.primary,
                      bevelColor: AppColors.primaryDark,
                      borderColor: AppColors.primaryLight,
                      extraGlow: [
                        BoxShadow(
                          color: AppColors.glowPrimary,
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      onPressed: () {
                        HapticService.instance.heavyImpact();
                        AudioService.instance.playButtonClick();
                        Navigator.of(context).pop();
                        widget.onSelectLevel(_selectedLevel);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.textWhite,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'START MATCH',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textWhite,
                              letterSpacing: 1.0,
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

  Widget _buildLevelCard(GameLevel level, bool isLocked, bool isSelected) {
    Color cardBorder = isSelected
        ? AppColors.primary
        : (isLocked ? AppColors.border.withValues(alpha: 0.5) : AppColors.border);
    Color cardBg = isSelected
        ? AppColors.primary.withValues(alpha: 0.08)
        : (isLocked
            ? AppColors.surfaceSecondary.withValues(alpha: 0.4)
            : AppColors.surfaceSecondary);

    return InkWell(
      onTap: () => _onLevelTap(level),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cardBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.glowPrimary,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            // Level indicator icon or Lock
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLocked
                    ? AppColors.surfaceMuted.withValues(alpha: 0.5)
                    : (isSelected
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Icon(
                isLocked
                    ? Icons.lock_rounded
                    : (isSelected
                        ? Icons.check_rounded
                        : (level == GameLevel.master
                            ? Icons.workspace_premium_rounded
                            : Icons.military_tech_rounded)),
                color: isLocked
                    ? AppColors.textSecondary
                    : (isSelected ? Colors.white : AppColors.primary),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Level Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        level.displayName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: isLocked
                              ? AppColors.textSecondary.withValues(alpha: 0.6)
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (level == GameLevel.master) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.winHighlight.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.winHighlight, width: 0.8),
                          ),
                          child: const Text(
                            'MAX',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.winHighlight,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _buildPill('${level.rows}×${level.cols} Grid', isLocked),
                      const SizedBox(width: 6),
                      _buildPill('${level.winLen} in a row', isLocked),
                    ],
                  ),
                ],
              ),
            ),

            // Lock indicator if in vsBot mode
            if (widget.isVsBot && isLocked)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  'LOCKED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.defeat.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String text, bool isLocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.border.withValues(alpha: isLocked ? 0.3 : 0.8),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isLocked
              ? AppColors.textSecondary.withValues(alpha: 0.5)
              : AppColors.textSecondary,
        ),
      ),
    );
  }
}

