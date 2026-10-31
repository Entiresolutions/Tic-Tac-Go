import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../game/caro/caro_controller.dart';
import '../../../../game/caro/caro_board.dart';
import '../../../../game/caro/game_config.dart';
import '../../../../services/audio_service.dart';
import '../../../../services/haptic_service.dart';
import '../../../widgets/bouncing_game_button.dart';
import '../../../widgets/game_glow_scaffold.dart';
import '../../../widgets/caro/caro_leave_dialog.dart';
import '../../../widgets/caro/caro_pause_dialog.dart';
import '../../../widgets/caro/caro_surrender_dialog.dart';
import '../../../widgets/caro/caro_end_game_dialog.dart';
import '../caro_home_screen.dart';

class CaroScreen extends StatefulWidget {
  const CaroScreen({super.key});

  @override
  State<CaroScreen> createState() => _CaroScreenState();
}

class _CaroScreenState extends State<CaroScreen> {
  bool _hasShownEndDialog = false;
  bool _isNavigatingToRematch = false;
  CaroController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller = context.read<CaroController>();
      _controller!.connectToServer();
      _controller!.addListener(_checkGameEnd);
    });
  }

  @override
  void dispose() {
    _controller?.removeListener(_checkGameEnd);
    _controller?.disconnect();
    super.dispose();
  }

  void _checkGameEnd() {
    if (_controller == null) return;

    if (!_controller!.isFinished) {
      _hasShownEndDialog = false;
    }

    if (_controller!.isFinished && !_hasShownEndDialog) {
      _hasShownEndDialog = true;

      // Haptic celebration / alert
      if (_controller!.winnerId == _controller!.myUserId) {
        if (_controller!.isMasterBeaten) {
          HapticService.instance.winningStreak();
        } else {
          HapticService.instance.heavyImpact();
        }
      } else if (_controller!.winnerId != null) {
        HapticService.instance.mediumImpact();
      } else {
        HapticService.instance.drawFeedback();
      }

      // Show match result center dialog after winning line animation
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || _controller == null || !_controller!.isFinished) return;
        CaroEndGameDialog.show(
          context: context,
          controller: _controller!,
          onPlayAgain: () {
            HapticService.instance.lightImpact();
            AudioService.instance.playButtonClick();
            Navigator.of(context).pop();
            _hasShownEndDialog = false;
            _controller!.resetGame();
          },
          onNextLevel: (nextLevel) {
            HapticService.instance.heavyImpact();
            AudioService.instance.playButtonClick();
            Navigator.of(context).pop();
            _hasShownEndDialog = false;
            _navigateToLevel(nextLevel);
          },
          onGoHome: () {
            HapticService.instance.lightImpact();
            AudioService.instance.playButtonClick();
            _controller!.disconnect();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const CaroHomeScreen()),
              (route) => false,
            );
          },
        );
      });
    }

    if (_controller!.newMatchId != null && !_isNavigatingToRematch) {
      _isNavigatingToRematch = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _navigateToNewMatch(_controller!.newMatchId!);
        }
      });
    }
  }

  void _navigateToLevel(GameLevel nextLevel) {
    if (!mounted) return;

    final oldMyWins = _controller?.myWins ?? 0;
    final oldOpponentWins = _controller?.opponentWins ?? 0;
    final oldDraws = _controller?.draws ?? 0;
    final oldMyRating = _controller?.myRating;
    final oldOpponentRating = _controller?.opponentRating;
    final oldIsOffline = _controller?.isOffline ?? true;
    final oldIsVsBot = _controller?.isVsBot ?? true;

    _controller?.removeListener(_checkGameEnd);
    _controller?.disconnect();

    final newMatchId = DateTime.now().millisecondsSinceEpoch;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) {
            final newController = CaroController(
              level: nextLevel,
              matchId: newMatchId,
              isOffline: oldIsOffline,
              isVsBot: oldIsVsBot,
              initialMyRating: oldMyRating,
              initialOpponentRating: oldOpponentRating,
            );
            newController.myWins = oldMyWins;
            newController.opponentWins = oldOpponentWins;
            newController.draws = oldDraws;
            return newController;
          },
          child: const CaroScreen(),
        ),
      ),
    );
  }

  void _navigateToNewMatch(int newMatchId) {
    if (!mounted) return;

    final oldMyWins = _controller?.myWins ?? 0;
    final oldOpponentWins = _controller?.opponentWins ?? 0;
    final oldDraws = _controller?.draws ?? 0;
    final oldMyRating = _controller?.myRating;
    final oldOpponentRating = _controller?.opponentRating;
    final oldIsOffline = _controller?.isOffline ?? true;
    final oldIsVsBot = _controller?.isVsBot ?? false;
    final oldLevel = _controller?.level;
    final oldConfig = _controller?.config;

    if (_controller != null) {
      _controller!.newMatchId = null;
    }
    _controller?.removeListener(_checkGameEnd);
    _controller?.disconnect();

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) {
            final newController = CaroController(
              level: oldLevel,
              config: oldConfig,
              matchId: newMatchId,
              isOffline: oldIsOffline,
              isVsBot: oldIsVsBot,
              initialMyRating: oldMyRating,
              initialOpponentRating: oldOpponentRating,
            );
            newController.myWins = oldMyWins;
            newController.opponentWins = oldOpponentWins;
            newController.draws = oldDraws;
            return newController;
          },
          child: const CaroScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CaroController>();
    final isPlayerTurn = controller.currentTurn == "X";

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: GameGlowScaffold(
        topGlowColor:
            isPlayerTurn ? AppColors.bgGlowBlue : AppColors.bgGlowRed,
        bottomGlowColor:
            isPlayerTurn ? AppColors.bgGlowCyan : AppColors.bgGlowAmber,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth <= 50 || constraints.maxHeight <= 50) {
                return const SizedBox.shrink();
              }

              final bool isLandscape =
                  constraints.maxWidth > constraints.maxHeight;

              if (isLandscape) {
                return _buildLandscapeLayout(controller);
              }
              return _buildPortraitLayout(controller);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(CaroController controller) {
    return Column(
      children: [
        _buildTopControlBar(controller),
        _buildOpponentHeader(controller),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CaroBoard(),
                if (controller.isStartBannerShowing)
                  _StartBannerOverlay(controller: controller),
              ],
            ),
          ),
        ),
        _buildGameActionButtons(controller),
        _buildPlayerFooter(controller),
      ],
    );
  }

  Widget _buildLandscapeLayout(CaroController controller) {
    return Column(
      children: [
        _buildTopControlBar(controller),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 220,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildOpponentHeader(controller),
                      const SizedBox(height: 8),
                      _buildGameActionButtons(controller),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const CaroBoard(),
                      if (controller.isStartBannerShowing)
                        _StartBannerOverlay(controller: controller),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 220,
                child: SingleChildScrollView(
                  child: _buildPlayerFooter(controller),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameActionButtons(CaroController controller) {
    final bool isBotThinking = controller.isVsBot && controller.currentTurn == "O";
    final bool canHint = !controller.isFinished &&
        !controller.isPaused &&
        !controller.isStartBannerShowing &&
        !isBotThinking;
    final bool canUndo = controller.canUndo && !isBotThinking;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 6,
        children: [
          // Hint Button
          BouncingGameButton(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            backgroundColor: canHint
                ? AppColors.winHighlight.withValues(alpha: 0.14)
                : AppColors.surfaceSecondary.withValues(alpha: 0.5),
            bevelColor: canHint
                ? AppColors.iconGold.withValues(alpha: 0.5)
                : AppColors.borderDark,
            borderColor: canHint
                ? AppColors.winHighlight.withValues(alpha: 0.8)
                : AppColors.border,
            onPressed: canHint
                ? () {
                    HapticService.instance.lightImpact();
                    AudioService.instance.playButtonClick();
                    controller.requestHint();
                  }
                : () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: canHint ? AppColors.winHighlight : AppColors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Hint',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: canHint
                        ? AppColors.winHighlight
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Undo Button
          BouncingGameButton(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            backgroundColor: canUndo
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.surfaceSecondary.withValues(alpha: 0.5),
            bevelColor: canUndo
                ? AppColors.primaryDark.withValues(alpha: 0.5)
                : AppColors.borderDark,
            borderColor: canUndo
                ? AppColors.primary.withValues(alpha: 0.8)
                : AppColors.border,
            onPressed: canUndo
                ? () {
                    HapticService.instance.lightImpact();
                    AudioService.instance.playButtonClick();
                    controller.undoMove();
                  }
                : () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.undo_rounded,
                  color: canUndo ? AppColors.primary : AppColors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Undo',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: canUndo ? AppColors.primary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopControlBar(CaroController controller) {
    return LayoutBuilder(
      builder: (context, barConstraints) {
        final bool isCompact = barConstraints.maxWidth < 380;
        final bool isUltraCompact = barConstraints.maxWidth < 340;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: isUltraCompact ? 8 : 12,
            vertical: 4,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isUltraCompact ? 6 : 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowSubtle,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Leave Button
              BouncingGameButton(
                height: 34,
                padding: EdgeInsets.symmetric(
                  horizontal: isUltraCompact ? 8 : 10,
                ),
                backgroundColor: AppColors.surfaceSecondary,
                bevelColor: AppColors.borderDark,
                borderColor: AppColors.border,
                onPressed: () {
                  HapticService.instance.lightImpact();
                  AudioService.instance.playButtonClick();
                  CaroLeaveDialog.show(
                    context,
                    () {
                      controller.disconnect();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const CaroHomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                      size: 13,
                    ),
                    if (!isUltraCompact) ...[
                      const SizedBox(width: 4),
                      Text(
                        'Leave',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Center Mode Badge
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: controller.isPaused
                        ? AppColors.winHighlight.withValues(alpha: 0.12)
                        : (controller.isFinished
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : AppColors.surfaceSecondary),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controller.isPaused
                          ? AppColors.winHighlight
                          : (controller.isFinished
                              ? AppColors.primaryLight
                              : AppColors.border),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        controller.isPaused
                            ? Icons.pause_circle_filled_rounded
                            : (controller.isFinished
                                ? Icons.military_tech_rounded
                                : (controller.isVsBot
                                    ? Icons.smart_toy_rounded
                                    : Icons.people_alt_rounded)),
                        size: 14,
                        color: controller.isPaused
                            ? AppColors.winHighlight
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          controller.isPaused
                              ? 'PAUSED'
                              : (controller.isFinished
                                  ? 'FINISHED'
                                  : (controller.level != null
                                      ? controller.level!.displayName.toUpperCase()
                                      : (controller.isVsBot
                                          ? 'VS BOT'
                                          : '2 PLAYERS'))),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            color: controller.isPaused
                                ? AppColors.winHighlight
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${controller.winLen}-IN-ROW',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Pause / Resume Button (Restart is intentionally removed from top bar)
              if (!controller.isFinished)
                BouncingGameButton(
                  height: 34,
                  padding: EdgeInsets.symmetric(
                    horizontal: isUltraCompact ? 8 : 10,
                  ),
                  backgroundColor: controller.isPaused
                      ? AppColors.winHighlight
                      : AppColors.surfaceSecondary,
                  bevelColor: controller.isPaused
                      ? AppColors.iconGold
                      : AppColors.borderDark,
                  borderColor: controller.isPaused
                      ? AppColors.iconGold
                      : AppColors.border,
                  onPressed: () {
                    HapticService.instance.lightImpact();
                    AudioService.instance.playButtonClick();
                    if (controller.isPaused) {
                      controller.resumeGame();
                    } else {
                      controller.pauseGame();
                      CaroPauseDialog.show(
                        context: context,
                        controller: controller,
                        onResume: () => controller.resumeGame(),
                        onRestart: () => controller.resetGame(),
                        onLeave: () {
                          controller.disconnect();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const CaroHomeScreen(),
                            ),
                            (route) => false,
                          );
                        },
                      );
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        controller.isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: controller.isPaused
                            ? AppColors.textWhite
                            : AppColors.textPrimary,
                        size: 16,
                      ),
                      if (!isUltraCompact) ...[
                        const SizedBox(width: 4),
                        Text(
                          controller.isPaused ? 'Resume' : 'Pause',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: controller.isPaused
                                ? AppColors.textWhite
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else
                SizedBox(width: isUltraCompact ? 34 : 68),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOpponentHeader(CaroController controller) {
    final opponentName =
        controller.opponentUsername ?? (controller.isVsBot ? 'Bot AI' : 'Player 2');
    final opponentSymbol = controller.mySymbol == 'X' ? 'O' : 'X';
    final isOpponentTurn = controller.currentTurn == opponentSymbol;
    final opponentRating = controller.opponentRating ?? 1200;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border.all(
          color: isOpponentTurn ? AppColors.oPrimary : AppColors.border,
          width: isOpponentTurn ? 2.0 : 1.0,
        ),
        boxShadow: [
          if (isOpponentTurn)
            const BoxShadow(
              color: AppColors.glowO,
              blurRadius: 14,
              offset: Offset(0, 4),
            )
          else
            BoxShadow(
              color: AppColors.shadowSubtle,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildAvatarWithTimer(
                isTurn: isOpponentTurn,
                symbol: opponentSymbol,
                isO: true,
                timeLeft: controller.timeLeft,
                initialTime: controller.initialTimeLeft ?? 30,
              ),
              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      opponentName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.military_tech_rounded,
                          color: AppColors.winHighlight,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '$opponentRating ELO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${controller.opponentWins} W',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.oPrimary,
                  ),
                ),
              ),
            ],
          ),

          if (isOpponentTurn)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.oPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "THINKING...",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.oPrimary,
                  letterSpacing: 0.6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerFooter(CaroController controller) {
    final myName = controller.myUsername ?? 'You';
    final mySymbol = controller.mySymbol ?? 'X';
    final isMyTurn = controller.currentTurn == mySymbol;
    final myRating = controller.myRating ?? 1200;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: (isMyTurn && !controller.isFinished)
              ? AppColors.primary
              : AppColors.border,
          width: (isMyTurn && !controller.isFinished) ? 2.0 : 1.0,
        ),
        boxShadow: [
          if (isMyTurn && !controller.isFinished)
            const BoxShadow(
              color: AppColors.glowPrimary,
              blurRadius: 14,
              offset: Offset(0, -4),
            )
          else
            BoxShadow(
              color: AppColors.shadowSubtle,
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMyTurn && !controller.isFinished)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "YOUR TURN",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.6,
                ),
              ),
            ),

          Row(
            children: [
              _buildAvatarWithTimer(
                isTurn: isMyTurn,
                symbol: mySymbol,
                isO: false,
                timeLeft: controller.timeLeft,
                initialTime: controller.initialTimeLeft ?? 30,
              ),
              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      myName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.military_tech_rounded,
                          color: AppColors.winHighlight,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '$myRating ELO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${controller.myWins} W',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),

              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(
                  Icons.flag_rounded,
                  color: AppColors.defeat,
                  size: 20,
                ),
                tooltip: 'Surrender',
                onPressed: () {
                  HapticService.instance.lightImpact();
                  AudioService.instance.playButtonClick();
                  CaroSurrenderDialog.show(
                    context,
                    () => controller.surrender(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWithTimer({
    required bool isTurn,
    required String symbol,
    required bool isO,
    required int? timeLeft,
    required int initialTime,
  }) {
    Color timerColor = AppColors.timerNormal;
    if (timeLeft != null) {
      if (timeLeft <= 5) {
        timerColor = AppColors.timerCritical;
      } else if (timeLeft <= 12) {
        timerColor = AppColors.timerWarning;
      }
    }

    final double progress = (timeLeft != null && initialTime > 0)
        ? (timeLeft / initialTime).clamp(0.0, 1.0)
        : 1.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (isTurn)
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3.0,
              backgroundColor: timerColor.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation(timerColor),
            ),
          ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isO ? AppColors.oSecondary : AppColors.xSecondary,
            border: Border.all(
              color: isO ? AppColors.oPrimary : AppColors.primary,
              width: 2.0,
            ),
          ),
          child: Center(
            child: Text(
              symbol,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Start Banner Overlay that displays "START" + "Connect X to win"
/// Auto-dismisses after 2 seconds and unblocks input.
class _StartBannerOverlay extends StatefulWidget {
  final CaroController controller;

  const _StartBannerOverlay({required this.controller});

  @override
  State<_StartBannerOverlay> createState() => _StartBannerOverlayState();
}

class _StartBannerOverlayState extends State<_StartBannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _opacity = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();

    _timer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _anim.reverse().then((_) {
          if (mounted) {
            widget.controller.dismissStartBanner();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final winLen = widget.controller.winLen;
    final levelName = widget.controller.level?.displayName;

    return Center(
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface,
                  AppColors.surfaceSecondary,
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.winHighlight, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.winHighlight.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.flag_rounded,
                      color: AppColors.winHighlight,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'START',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: AppColors.winHighlight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Connect $winLen to win',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (levelName != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '$levelName Rank • ${widget.controller.rows}×${widget.controller.cols}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
