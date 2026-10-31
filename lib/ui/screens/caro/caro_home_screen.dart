import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/user_model.dart';
import '../../../../game/caro/caro_controller.dart';
import '../../../../game/caro/game_config.dart';
import '../../../../services/audio_service.dart';
import '../../../../services/haptic_service.dart';
import '../../../../services/local_storage_service.dart';
import '../../widgets/bouncing_game_button.dart';
import '../../widgets/game_glow_scaffold.dart';
import '../../widgets/caro/caro_tutorial_dialog.dart';
import '../../widgets/caro/caro_level_dialog.dart';
import 'play/caro_playing_screen.dart';
import 'history/match_history_screen.dart';
import 'profile/settings_screen.dart';

class CaroHomeScreen extends StatefulWidget {
  const CaroHomeScreen({super.key});

  @override
  State<CaroHomeScreen> createState() => _CaroHomeScreenState();
}

class _CaroHomeScreenState extends State<CaroHomeScreen>
    with SingleTickerProviderStateMixin {
  UserModel? _currentUser;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _checkLoginAndLoadData();
    AudioService.instance.startBgm();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginAndLoadData() async {
    try {
      final user = await LocalStorageService.getCurrentUserModel();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      // Graceful fallback to default user model
    } finally {
      if (mounted) {
        _animationController.forward();
      }
    }
  }

  Future<void> _startBotMatch() async {
    HapticService.instance.mediumImpact();
    await CaroTutorialDialog.showIfFirstTime(context);
    if (!mounted) return;

    CaroLevelSelectDialog.show(
      context: context,
      isVsBot: true,
      onSelectLevel: (selectedLevel) {
        _launchMatch(selectedLevel, isVsBot: true);
      },
    );
  }

  Future<void> _startPassAndPlayMatch() async {
    HapticService.instance.mediumImpact();
    await CaroTutorialDialog.showIfFirstTime(context);
    if (!mounted) return;

    CaroLevelSelectDialog.show(
      context: context,
      isVsBot: false,
      onSelectLevel: (selectedLevel) {
        _launchMatch(selectedLevel, isVsBot: false);
      },
    );
  }

  void _launchMatch(GameLevel level, {required bool isVsBot}) {
    final user = _currentUser ??
        UserModel(
          id: 1,
          username: "Player 1",
          email: "player@local.game",
          rating: 1200,
        );

    final matchId = DateTime.now().millisecondsSinceEpoch;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => CaroController(
            level: level,
            matchId: matchId,
            isOffline: true,
            isVsBot: isVsBot,
            initialMyRating: user.rating ?? 1200,
            initialOpponentRating: isVsBot ? 1400 : 1200,
          ),
          child: const CaroScreen(),
        ),
      ),
    ).then((_) => _checkLoginAndLoadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: GameGlowScaffold(
        topGlowColor: AppColors.bgGlowBlue,
        bottomGlowColor: AppColors.bgGlowCyan,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth <= 50 || constraints.maxHeight <= 50) {
                return const SizedBox.shrink();
              }

              final double screenWidth = constraints.maxWidth;
              final bool isTablet = screenWidth > 600;

              return Column(
                children: [
                  _buildTopBar(isTablet),
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 48.0 : 20.0,
                              vertical: 8.0,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isTablet ? 540.0 : double.infinity,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Logo / Hero Graphic
                                  _buildGameLogo(isTablet),
                                  const SizedBox(height: 16),

                                  // Tagline
                                  Text(
                                    'Connect 5 – Outsmart – Win!',
                                    style: TextStyle(
                                      fontSize: isTablet ? 18 : 15,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),

                                  // Mode Action Buttons (3D Tactile)
                                  BouncingGameButton(
                                    height: isTablet ? 64 : 56,
                                    backgroundColor: AppColors.primary,
                                    bevelColor: AppColors.buttonBevel,
                                    extraGlow: const [
                                      BoxShadow(
                                        color: AppColors.glowPrimary,
                                        blurRadius: 14,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                    onPressed: _startBotMatch,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.smart_toy_rounded,
                                          color: AppColors.textWhite,
                                          size: 26,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'PLAY WITH BOT',
                                          style: TextStyle(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textWhite,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  BouncingGameButton(
                                    height: isTablet ? 64 : 56,
                                    backgroundColor: AppColors.surface,
                                    bevelColor: AppColors.buttonWhiteBevel,
                                    borderColor: AppColors.border,
                                    extraGlow: [
                                      BoxShadow(
                                        color: AppColors.shadowSubtle,
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                    onPressed: _startPassAndPlayMatch,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.people_rounded,
                                          color: AppColors.primary,
                                          size: 26,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '2 PLAYERS',
                                          style: TextStyle(
                                            fontSize: isTablet ? 18 : 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Quick History Card
                                  _buildHistoryShortcutCard(isTablet),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      // bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  Widget _buildGameLogo(bool isTablet) {
    final double logoDim = isTablet ? 160.0 : 130.0;
    return Container(
      width: logoDim,
      height: logoDim,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isTablet ? 24.0 : 20.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.glowPrimary,
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isTablet ? 24.0 : 20.0),
        child: Image.asset(
          'assets/tic-tac-go-logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildHistoryShortcutCard(bool isTablet) {
    return GestureDetector(
      onTap: () {
        HapticService.instance.lightImpact();
        AudioService.instance.playButtonClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MatchHistoryScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowSubtle,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.glowPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.history_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Match History',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View past wins, losses & replays',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 420;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 48.0 : (isCompact ? 12.0 : 20.0),
            vertical: 8.0,
          ),
          child: Row(
            children: [
              // Brand badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowSubtle,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.grid_4x4_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Tic Tac GO',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // How to play Rules / Tutorial Button
              BouncingGameButton(
                height: 38,
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 12),
                backgroundColor: AppColors.surface,
                bevelColor: AppColors.buttonWhiteBevel,
                borderColor: AppColors.border,
                onPressed: () {
                  HapticService.instance.lightImpact();
                  CaroTutorialDialog.show(context);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: 4),
                      Text(
                        'Rules',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Settings Button
              BouncingGameButton(
                height: 38,
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 12),
                backgroundColor: AppColors.surface,
                bevelColor: AppColors.buttonWhiteBevel,
                borderColor: AppColors.border,
                onPressed: () {
                  HapticService.instance.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.settings_rounded,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
