import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tic_tac_go/services/ad_service.dart';
import 'package:tic_tac_go/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdService', () {
    test('stores configured production AdMob App ID and Ad Unit IDs', () {
      expect(AdService.appId, 'ca-app-pub-3794659976212193~8954509677');
      expect(
        AdService.prodInterstitialAdUnitId,
        'ca-app-pub-3794659976212193/4597617218',
      );
      expect(
        AdService.prodRewardedInterstitialAdUnitId,
        'ca-app-pub-3794659976212193/4281214600',
      );
    });

    test('showInterstitialAd calls onAdClosed immediately when unloaded',
        () async {
      bool closedCalled = false;

      final shown = await AdService.instance.showInterstitialAd(
        onAdClosed: () => closedCalled = true,
      );

      expect(shown, isFalse);
      expect(closedCalled, isTrue);
    });

    test('showRewardedInterstitialAd triggers onAdNotReady when unloaded',
        () async {
      bool rewardEarned = false;
      bool notReadyCalled = false;

      final shown = await AdService.instance.showRewardedInterstitialAd(
        onRewardEarned: () => rewardEarned = true,
        onAdNotReady: () => notReadyCalled = true,
      );

      expect(shown, isFalse);
      expect(rewardEarned, isFalse);
      expect(notReadyCalled, isTrue);
    });

    test('init completes safely on non-mobile test hosts', () async {
      await AdService.instance.init();
      expect(AdService.instance.isInterstitialAdReady, isFalse);
      expect(AdService.instance.isAdReady, isFalse);
    });
  });

  group('First-match pre-game ad gating', () {
    test('hasPlayedFirstMatch defaults to false and persists true once marked',
        () async {
      SharedPreferences.setMockInitialValues({});
      LocalStorageService.resetPrefsForTesting(null);

      expect(await LocalStorageService.hasPlayedFirstMatch(), isFalse);

      await LocalStorageService.markFirstMatchPlayed();

      expect(await LocalStorageService.hasPlayedFirstMatch(), isTrue);
    });
  });
}
