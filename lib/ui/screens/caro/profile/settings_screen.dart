import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../services/audio_service.dart';
import '../../../../services/haptic_service.dart';
import '../../../widgets/game_glow_scaffold.dart';
import '../../../widgets/caro/caro_tutorial_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEffects = true;
  bool _music = true;
  bool _hapticFeedback = true;
  double _soundEffectsVolume = 0.85;
  double _musicVolume = 0.70;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await AudioService.instance.init();
    await HapticService.instance.init();

    if (mounted) {
      setState(() {
        _soundEffects = AudioService.instance.soundEffectsEnabled;
        _music = AudioService.instance.musicEnabled;
        _hapticFeedback = HapticService.instance.isEnabled;
        _soundEffectsVolume = AudioService.instance.soundEffectsVolume;
        _musicVolume = AudioService.instance.musicVolume;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSoundEffects(bool value) async {
    setState(() => _soundEffects = value);
    await AudioService.instance.setSoundEffectsEnabled(value);
  }

  Future<void> _updateMusic(bool value) async {
    setState(() => _music = value);
    await AudioService.instance.setMusicEnabled(value);
  }

  Future<void> _updateHapticFeedback(bool value) async {
    setState(() => _hapticFeedback = value);
    await HapticService.instance.setEnabled(value);
  }

  Future<void> _updateSoundEffectsVolume(double value) async {
    setState(() => _soundEffectsVolume = value);
    await AudioService.instance.setSoundEffectsVolume(value);
  }

  Future<void> _updateMusicVolume(double value) async {
    setState(() => _musicVolume = value);
    await AudioService.instance.setMusicVolume(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textWhite),
          tooltip: 'Back',
          onPressed: () {
            HapticService.instance.lightImpact();
            AudioService.instance.playButtonClick();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textWhite,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: GameGlowScaffold(
        topGlowColor: AppColors.bgGlowBlue,
        bottomGlowColor: AppColors.bgGlowCyan,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  final isDarkMode = themeProvider.isDarkMode;

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                    children: [
                      // 🎨 Appearance Section
                      _buildSection(
                        title: 'Appearance',
                        children: [
                          _buildThemeSwitchTile(
                            isDarkMode: isDarkMode,
                            onChanged: (val) {
                              themeProvider.setDarkMode(val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 🔊 Audio & Feedback Section
                      _buildSection(
                        title: 'Audio & Feedback',
                        children: [
                          // Sound Effects Toggle
                          _buildSwitchTile(
                            icon: Icons.volume_up_rounded,
                            title: 'Sound Effects',
                            subtitle: 'Button taps, stone moves & laser strikes',
                            value: _soundEffects,
                            onChanged: _updateSoundEffects,
                          ),
                          // Sound Effects Volume Slider
                          _buildSliderTile(
                            icon: Icons.graphic_eq_rounded,
                            title: 'Sound Effects Volume',
                            value: _soundEffectsVolume,
                            enabled: _soundEffects,
                            onChanged: _updateSoundEffectsVolume,
                          ),
                          Divider(color: AppColors.border, height: 1),

                          // Music Toggle
                          _buildSwitchTile(
                            icon: Icons.music_note_rounded,
                            title: 'Background Music',
                            subtitle: 'Continuous ambient game soundtrack',
                            value: _music,
                            onChanged: _updateMusic,
                          ),
                          // Music Volume Slider
                          _buildSliderTile(
                            icon: Icons.surround_sound_rounded,
                            title: 'Music Volume',
                            value: _musicVolume,
                            enabled: _music,
                            onChanged: _updateMusicVolume,
                          ),
                          Divider(color: AppColors.border, height: 1),

                          // Haptic Feedback Toggle
                          _buildSwitchTile(
                            icon: Icons.vibration_rounded,
                            title: 'Haptic Feedback',
                            subtitle: 'Tactile vibration on moves, clicks & streaks',
                            value: _hapticFeedback,
                            onChanged: _updateHapticFeedback,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ℹ️ Game Info Section
                      _buildSection(
                        title: 'Game Info',
                        children: [
                          _buildInfoTile(
                            icon: Icons.school_rounded,
                            title: 'How to Play',
                            value: 'Tutorial',
                            onTap: () {
                              HapticService.instance.lightImpact();
                              AudioService.instance.playButtonClick();
                              CaroTutorialDialog.show(context);
                            },
                          ),
                          Divider(color: AppColors.border, height: 1),
                          _buildInfoTile(
                            icon: Icons.grid_4x4_rounded,
                            title: 'Board Format',
                            value: '7 × 7 Grid',
                          ),
                          Divider(color: AppColors.border, height: 1),
                          _buildInfoTile(
                            icon: Icons.emoji_events_rounded,
                            title: 'Win Condition',
                            value: '5 in a row',
                          ),
                          Divider(color: AppColors.border, height: 1),
                          _buildInfoTile(
                            icon: Icons.offline_bolt_rounded,
                            title: 'Game Storage',
                            value: 'Local & Offline',
                          ),
                          Divider(color: AppColors.border, height: 1),
                          _buildInfoTile(
                            icon: Icons.info_outline_rounded,
                            title: 'Version',
                            value: '1.0.0',
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowSubtle,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSwitchTile({
    required bool isDarkMode,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                key: ValueKey<bool>(isDarkMode),
                color: isDarkMode ? AppColors.primary : const Color(0xFFD97706),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Dark Mode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDarkMode
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isDarkMode ? 'Dark' : 'Light',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDarkMode
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isDarkMode
                      ? 'Deep navy & neon blue accents'
                      : 'Clean canvas & strategic blue',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDarkMode,
            onChanged: (val) {
              HapticService.instance.lightImpact();
              onChanged(val);
            },
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      value: value,
      onChanged: (val) {
        HapticService.instance.lightImpact();
        onChanged(val);
      },
      activeThumbColor: AppColors.primary,
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required double value,
    required bool enabled,
    required ValueChanged<double> onChanged,
  }) {
    final int percent = (value * 100).round();
    final Color activeColor = enabled ? AppColors.primary : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: activeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: enabled ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.border.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: activeColor,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: activeColor,
              inactiveTrackColor: AppColors.border,
              thumbColor: activeColor,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayColor: activeColor.withValues(alpha: 0.15),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: onTap != null ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }
}
