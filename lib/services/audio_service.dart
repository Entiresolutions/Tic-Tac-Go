import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized, high-performance audio engine for Tic Tac GO.
/// Manages background soundtrack looping, sound effects, volume control,
/// and app lifecycle pausing/resuming.
class AudioService with WidgetsBindingObserver {
  AudioService._();
  static final AudioService instance = AudioService._();

  static const String prefKeySoundEffects = 'settings_sound_effects';
  static const String prefKeyMusic = 'settings_music';
  static const String prefKeyMusicVolume = 'settings_music_volume';
  static const String prefKeySoundEffectsVolume = 'settings_sound_effects_volume';

  static const String assetButton = 'sound/button.mp3';
  static const String assetTic = 'sound/tic.mp3';
  static const String assetLaser = 'sound/laser.mp3';
  static const String assetBgm = 'sound/tic-tac-go-game Soundtrack.mp3';

  // Dedicated players to prevent overlap and clipping
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _buttonPlayer = AudioPlayer();
  final AudioPlayer _movePlayer = AudioPlayer();
  final AudioPlayer _laserPlayer = AudioPlayer();

  bool _soundEffectsEnabled = true;
  bool _musicEnabled = true;
  double _musicVolume = 0.70;
  double _soundEffectsVolume = 0.85;

  bool _isBgmPlaying = false;
  bool _wasBgmPlayingBeforePause = false;
  bool _isInitialized = false;

  int _lastButtonSoundMs = 0;
  int _lastMoveSoundMs = 0;
  int _lastLaserSoundMs = 0;

  // Getters
  bool get soundEffectsEnabled => _soundEffectsEnabled;
  bool get musicEnabled => _musicEnabled;
  double get musicVolume => _musicVolume;
  double get soundEffectsVolume => _soundEffectsVolume;
  bool get isBgmPlaying => _isBgmPlaying;

  /// Initialize players, load preferences, and register lifecycle observer
  Future<void> init({bool forceReload = false}) async {
    if (_isInitialized && !forceReload) return;
    _isInitialized = true;

    WidgetsBinding.instance.addObserver(this);

    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEffectsEnabled = prefs.getBool(prefKeySoundEffects) ?? true;
      _musicEnabled = prefs.getBool(prefKeyMusic) ?? true;
      _musicVolume = prefs.getDouble(prefKeyMusicVolume) ?? 0.70;
      _soundEffectsVolume = prefs.getDouble(prefKeySoundEffectsVolume) ?? 0.85;

      // Configure BGM player for continuous seamless looping
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_musicEnabled ? _musicVolume : 0.0);

      // Configure SFX players
      await _buttonPlayer.setVolume(_soundEffectsEnabled ? _soundEffectsVolume : 0.0);
      await _movePlayer.setVolume(_soundEffectsEnabled ? _soundEffectsVolume : 0.0);
      await _laserPlayer.setVolume(_soundEffectsEnabled ? _soundEffectsVolume : 0.0);
    } catch (_) {
      // Fallback gracefully if SharedPreferences or audio system is restricted
    }
  }

  // ==========================================
  // BACKGROUND MUSIC (BGM)
  // ==========================================

  /// Start or resume background music looping
  Future<void> startBgm() async {
    if (!_isInitialized) await init();
    if (!_musicEnabled) return;

    try {
      await _bgmPlayer.setVolume(_musicVolume);
      if (!_isBgmPlaying) {
        await _bgmPlayer.stop();
        await _bgmPlayer.play(AssetSource(assetBgm));
        _isBgmPlaying = true;
      } else {
        await _bgmPlayer.resume();
      }
    } catch (_) {}
  }

  /// Pause background music (e.g. app in background)
  Future<void> pauseBgm() async {
    try {
      if (_isBgmPlaying) {
        await _bgmPlayer.pause();
      }
    } catch (_) {}
  }

  /// Resume background music if enabled
  Future<void> resumeBgm() async {
    if (!_musicEnabled) return;
    try {
      if (_isBgmPlaying) {
        await _bgmPlayer.resume();
      } else {
        await startBgm();
      }
    } catch (_) {}
  }

  /// Stop background music completely
  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
      _isBgmPlaying = false;
    } catch (_) {}
  }

  // ==========================================
  // SOUND EFFECTS (SFX)
  // ==========================================

  /// Button click tactile sound effect
  Future<void> playButtonClick() async {
    if (!_isInitialized) await init();
    if (!_soundEffectsEnabled) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastButtonSoundMs < 50) return; // Debounce rapid micro-taps
    _lastButtonSoundMs = now;

    try {
      await _buttonPlayer.setVolume(_soundEffectsVolume);
      await _buttonPlayer.stop();
      await _buttonPlayer.play(AssetSource(assetButton));
    } catch (_) {}
  }

  /// Tic/stone placement sound when X or O is placed on the board
  Future<void> playMovePlacement() async {
    if (!_isInitialized) await init();
    if (!_soundEffectsEnabled) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastMoveSoundMs < 60) return;
    _lastMoveSoundMs = now;

    try {
      await _movePlayer.setVolume(_soundEffectsVolume);
      await _movePlayer.stop();
      await _movePlayer.play(AssetSource(assetTic));
    } catch (_) {}
  }

  /// Laser strike sound synchronized with the winning-line animation
  Future<void> playLaserStrike() async {
    if (!_isInitialized) await init();
    if (!_soundEffectsEnabled) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastLaserSoundMs < 300) return; // Avoid re-triggering during single animation
    _lastLaserSoundMs = now;

    try {
      await _laserPlayer.setVolume(_soundEffectsVolume);
      await _laserPlayer.stop();
      await _laserPlayer.play(AssetSource(assetLaser));
    } catch (_) {}
  }

  // ==========================================
  // SETTINGS & VOLUME CONTROLS
  // ==========================================

  /// Toggle Sound Effects ON/OFF
  Future<void> setSoundEffectsEnabled(bool enabled) async {
    _soundEffectsEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKeySoundEffects, enabled);

      final vol = enabled ? _soundEffectsVolume : 0.0;
      await _buttonPlayer.setVolume(vol);
      await _movePlayer.setVolume(vol);
      await _laserPlayer.setVolume(vol);
    } catch (_) {}

    if (enabled) {
      playButtonClick();
    }
  }

  /// Toggle Background Music ON/OFF
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKeyMusic, enabled);

      if (enabled) {
        await _bgmPlayer.setVolume(_musicVolume);
        await startBgm();
      } else {
        await _bgmPlayer.pause();
        _isBgmPlaying = false;
      }
    } catch (_) {}
  }

  /// Adjust Music Volume (0.0 to 1.0)
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(prefKeyMusicVolume, _musicVolume);
      if (_musicEnabled) {
        await _bgmPlayer.setVolume(_musicVolume);
      }
    } catch (_) {}
  }

  /// Adjust Sound Effects Volume (0.0 to 1.0)
  Future<void> setSoundEffectsVolume(double volume) async {
    _soundEffectsVolume = volume.clamp(0.0, 1.0);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(prefKeySoundEffectsVolume, _soundEffectsVolume);
      if (_soundEffectsEnabled) {
        await _buttonPlayer.setVolume(_soundEffectsVolume);
        await _movePlayer.setVolume(_soundEffectsVolume);
        await _laserPlayer.setVolume(_soundEffectsVolume);
      }
    } catch (_) {}
  }

  // ==========================================
  // APP LIFECYCLE MANAGEMENT
  // ==========================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        if (_isBgmPlaying) {
          _wasBgmPlayingBeforePause = true;
          pauseBgm();
        }
        break;
      case AppLifecycleState.resumed:
        if (_wasBgmPlayingBeforePause && _musicEnabled) {
          _wasBgmPlayingBeforePause = false;
          resumeBgm();
        }
        break;
      case AppLifecycleState.detached:
        stopBgm();
        break;
    }
  }

  /// Dispose all audio players when app terminates
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgmPlayer.dispose();
    _buttonPlayer.dispose();
    _movePlayer.dispose();
    _laserPlayer.dispose();
    _isInitialized = false;
  }
}
