import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/audio_service.dart';
import '../../../services/haptic_service.dart';
import '../bouncing_game_button.dart';

/// Interactive, visual step-by-step Tutorial Dialog for "Tic Tac GO".
/// Automatically shown on the user's first game, or opened on demand.
class CaroTutorialDialog extends StatefulWidget {
  const CaroTutorialDialog({super.key});

  static const String prefKey = 'has_seen_tutorial';

  /// Check and show tutorial if this is the user's first time playing
  static Future<void> showIfFirstTime(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool hasSeen = prefs.getBool(prefKey) ?? false;
      if (!hasSeen && context.mounted) {
        await show(context);
        await prefs.setBool(prefKey, true);
      }
    } catch (_) {
      // Fallback
    }
  }

  /// Show the tutorial dialog explicitly
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const CaroTutorialDialog(),
    );
  }

  @override
  State<CaroTutorialDialog> createState() => _CaroTutorialDialogState();
}

class _CaroTutorialDialogState extends State<CaroTutorialDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_TutorialSlideData> _slides = [
    _TutorialSlideData(
      stepNumber: '1',
      title: 'Connect 5 in a Row',
      description:
          'Place your marks to create an unbroken line of 5 symbols horizontally, vertically, or diagonally on the 7×7 board to win!',
      icon: Icons.emoji_events_rounded,
      iconColor: AppColors.winHighlight,
      badgeText: 'WIN CONDITION',
    ),
    _TutorialSlideData(
      stepNumber: '2',
      title: 'Blue (X) vs Red (O)',
      description:
          'You play as X (Blue) and your opponent plays as O (Red). Plan your attacks while blocking opponent streaks before they reach 5!',
      icon: Icons.swap_horiz_rounded,
      iconColor: AppColors.primary,
      badgeText: 'TACTICS & DEFENSE',
    ),
    _TutorialSlideData(
      stepNumber: '3',
      title: '30-Second Turn Clock',
      description:
          'Every turn has a 30-second countdown timer. Think fast, outmaneuver your opponent, and take control of the center of the board!',
      icon: Icons.timer_rounded,
      iconColor: AppColors.timerNormal,
      badgeText: 'SPEED & FOCUS',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    HapticService.instance.lightImpact();
    AudioService.instance.playButtonClick();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onBack() {
    HapticService.instance.lightImpact();
    AudioService.instance.playButtonClick();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(side: BorderSide.none),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 390),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              const BoxShadow(
                color: AppColors.glowPrimary,
                blurRadius: 18,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Title & Skip Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 14, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'HOW TO PLAY',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: AppColors.textMuted,
                      tooltip: 'Skip',
                      onPressed: () {
                        HapticService.instance.lightImpact();
                        AudioService.instance.playButtonClick();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),

              Divider(color: AppColors.border, height: 1),

              // PageView of Tutorial Slides
              SizedBox(
                height: 310,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return _buildSlideContent(slide, index);
                  },
                ),
              ),

              Divider(color: AppColors.border, height: 1),

              // Bottom Control Bar (Indicator + Navigation Buttons)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Slide Indicators
                    Row(
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(right: 6),
                          width: _currentPage == i ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? AppColors.primary
                                : AppColors.borderDark,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    // Actions
                    Row(
                      children: [
                        if (_currentPage > 0) ...[
                          BouncingGameButton(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            backgroundColor: AppColors.surfaceSecondary,
                            bevelColor: AppColors.borderDark,
                            borderColor: AppColors.border,
                            onPressed: _onBack,
                            child: Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        BouncingGameButton(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          backgroundColor: AppColors.primary,
                          bevelColor: AppColors.primaryDark,
                          borderColor: AppColors.primaryDark,
                          onPressed: _onNext,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLastPage ? "Let's Play!" : 'Next',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textWhite,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isLastPage
                                    ? Icons.sports_esports_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 15,
                                color: AppColors.textWhite,
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildSlideContent(_TutorialSlideData slide, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Visual Illustration
          _buildVisualIllustration(index),

          const SizedBox(height: 16),

          // Badge tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: slide.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              slide.badgeText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: slide.iconColor,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Slide Title
          Text(
            slide.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Slide Description
          Text(
            slide.description,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Custom visual illustrations for each tutorial step
  Widget _buildVisualIllustration(int index) {
    switch (index) {
      case 0:
        // Mini diagram of 5 marks in a row with glowing line
        return Container(
          width: 220,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  5,
                  (i) => Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.winHighlight.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.winHighlight,
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'X',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.xPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 6,
                right: 6,
                child: Container(
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.winHighlight,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.glowWin,
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

      case 1:
        // VS chips illustration
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.xPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.xPrimary, width: 1.5),
              ),
              child: const Row(
                children: [
                  Text(
                    'X',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.xPrimary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'You (Blue)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.xPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'VS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.oPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.oPrimary, width: 1.5),
              ),
              child: const Row(
                children: [
                  Text(
                    'O',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.oPrimary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Opponent (Red)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.oPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 2:
      default:
        // 30s countdown clock illustration
        return Container(
          width: 140,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.timerNormal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.timerNormal, width: 1.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                color: AppColors.timerNormal,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '30s Clock',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: AppColors.timerNormal,
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _TutorialSlideData {
  final String stepNumber;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final String badgeText;

  const _TutorialSlideData({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.badgeText,
  });
}

