import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tic_tac_go/services/audio_service.dart';
import 'package:tic_tac_go/services/haptic_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HapticService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        HapticService.prefKeyHaptic: true,
      });
    });

    test('Loads default enabled value and toggles cleanly', () async {
      final haptic = HapticService.instance;
      await haptic.init();
      expect(haptic.isEnabled, isTrue);

      await haptic.setEnabled(false);
      expect(haptic.isEnabled, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(HapticService.prefKeyHaptic), isFalse);

      await haptic.setEnabled(true);
      expect(haptic.isEnabled, isTrue);
      expect(prefs.getBool(HapticService.prefKeyHaptic), isTrue);
    });

    test('Feedback methods execute without crashing when enabled or disabled', () async {
      final haptic = HapticService.instance;
      await haptic.setEnabled(true);
      await haptic.lightImpact();
      await haptic.selectionClick();
      await haptic.mediumImpact();
      await haptic.heavyImpact();
      await haptic.winningStreak();
      await haptic.drawFeedback();

      await haptic.setEnabled(false);
      await haptic.lightImpact();
      await haptic.selectionClick();
      await haptic.mediumImpact();
      await haptic.heavyImpact();
      await haptic.winningStreak();
      await haptic.drawFeedback();
    });
  });

  group('AudioService Settings Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        AudioService.prefKeySoundEffects: true,
        AudioService.prefKeyMusic: true,
        AudioService.prefKeyMusicVolume: 0.75,
        AudioService.prefKeySoundEffectsVolume: 0.80,
      });
    });

    test('Loads preferences and adjusts volumes within bounds', () async {
      final audio = AudioService.instance;
      await audio.init(forceReload: true);

      expect(audio.soundEffectsEnabled, isTrue);
      expect(audio.musicEnabled, isTrue);
      expect(audio.musicVolume, closeTo(0.75, 0.01));
      expect(audio.soundEffectsVolume, closeTo(0.80, 0.01));

      // Test volume clamps
      await audio.setMusicVolume(1.5);
      expect(audio.musicVolume, equals(1.0));

      await audio.setMusicVolume(-0.5);
      expect(audio.musicVolume, equals(0.0));

      await audio.setSoundEffectsVolume(0.5);
      expect(audio.soundEffectsVolume, equals(0.5));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble(AudioService.prefKeySoundEffectsVolume), equals(0.5));

      // Test toggles
      await audio.setMusicEnabled(false);
      expect(audio.musicEnabled, isFalse);
      expect(prefs.getBool(AudioService.prefKeyMusic), isFalse);

      await audio.setSoundEffectsEnabled(false);
      expect(audio.soundEffectsEnabled, isFalse);
      expect(prefs.getBool(AudioService.prefKeySoundEffects), isFalse);
    });
  });
}
