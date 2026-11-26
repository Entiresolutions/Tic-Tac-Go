import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manages Google Mobile Ads initialization, pre-game Interstitial ads,
/// and Rewarded Interstitial ads used to unlock in-game Hint and Undo actions.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const String appId = 'ca-app-pub-3794659976212193~8954509677';
  static const String prodInterstitialAdUnitId =
      'ca-app-pub-3794659976212193/4597617218';
  static const String prodRewardedInterstitialAdUnitId =
      'ca-app-pub-3794659976212193/4281214600';

  // Official Google AdMob test unit IDs for debug builds only.
  static const String _testAndroidInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testIosInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _testAndroidRewardedInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/5354046379';
  static const String _testIosRewardedInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/6978759866';

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  int _interstitialLoadAttempt = 0;
  Timer? _interstitialRetryTimer;

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isLoading = false;
  int _loadAttempt = 0;
  Timer? _retryTimer;

  static const int _maxRetryAttempts = 3;

  bool get _isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Whether a pre-game interstitial ad is loaded and ready to display.
  bool get isInterstitialAdReady => _interstitialAd != null;

  /// Whether a rewarded interstitial ad is loaded and ready to display.
  bool get isAdReady => _rewardedInterstitialAd != null;

  /// Active interstitial ad unit ID: uses Google test IDs in debug mode and the
  /// production AdMob unit ID in profile/release builds.
  String get interstitialAdUnitId {
    if (kDebugMode) {
      if (!kIsWeb && Platform.isIOS) {
        return _testIosInterstitialAdUnitId;
      }
      return _testAndroidInterstitialAdUnitId;
    }
    return prodInterstitialAdUnitId;
  }

  /// Active rewarded interstitial ad unit ID: uses Google test IDs in debug
  /// mode and the production AdMob unit ID in profile/release builds.
  String get rewardedInterstitialAdUnitId {
    if (kDebugMode) {
      if (!kIsWeb && Platform.isIOS) {
        return _testIosRewardedInterstitialAdUnitId;
      }
      return _testAndroidRewardedInterstitialAdUnitId;
    }
    return prodRewardedInterstitialAdUnitId;
  }

  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Initializes the Mobile Ads SDK and preloads initial ads.
  Future<void> init() async {
    if (_isInitialized || _isInitializing || !_isMobilePlatform) return;
    _isInitializing = true;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      loadInterstitialAd();
      loadRewardedInterstitialAd();
    } catch (e) {
      debugPrint('AdService.init error: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// Preloads an [InterstitialAd] if one is not already loaded or loading.
  void loadInterstitialAd() {
    if (!_isMobilePlatform ||
        _isInterstitialLoading ||
        _interstitialAd != null) {
      return;
    }

    _isInterstitialLoading = true;
    _interstitialRetryTimer?.cancel();

    try {
      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _isInterstitialLoading = false;
            _interstitialLoadAttempt = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
            _interstitialAd = null;
            _isInterstitialLoading = false;
            _scheduleInterstitialRetry();
          },
        ),
      );
    } catch (e) {
      debugPrint('InterstitialAd load exception: $e');
      _isInterstitialLoading = false;
    }
  }

  void _scheduleInterstitialRetry() {
    if (_interstitialLoadAttempt >= _maxRetryAttempts) return;
    _interstitialLoadAttempt += 1;
    final delaySeconds = 5 * _interstitialLoadAttempt;
    _interstitialRetryTimer?.cancel();
    _interstitialRetryTimer = Timer(Duration(seconds: delaySeconds), () {
      loadInterstitialAd();
    });
  }

  /// Displays a loaded pre-game interstitial ad before proceeding.
  ///
  /// Always invokes [onAdClosed] when the ad finishes or if no ad is ready so
  /// offline gameplay is never blocked. Returns `true` if an ad was shown.
  Future<bool> showInterstitialAd({
    required VoidCallback onAdClosed,
  }) async {
    final ad = _interstitialAd;
    if (ad == null) {
      _interstitialLoadAttempt = 0;
      loadInterstitialAd();
      onAdClosed();
      return false;
    }

    _interstitialAd = null;
    bool didInvokeClosed = false;

    void handleClosed() {
      if (didInvokeClosed) return;
      didInvokeClosed = true;
      onAdClosed();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        handleClosed();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('InterstitialAd failed to show: $error');
        ad.dispose();
        handleClosed();
        loadInterstitialAd();
      },
    );

    try {
      await ad.show();
      return true;
    } catch (e) {
      debugPrint('InterstitialAd show exception: $e');
      ad.dispose();
      handleClosed();
      loadInterstitialAd();
      return false;
    }
  }

  /// Preloads a [RewardedInterstitialAd] if one is not already loaded or loading.
  void loadRewardedInterstitialAd() {
    if (!_isMobilePlatform || _isLoading || _rewardedInterstitialAd != null) {
      return;
    }

    _isLoading = true;
    _retryTimer?.cancel();

    try {
      RewardedInterstitialAd.load(
        adUnitId: rewardedInterstitialAdUnitId,
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (RewardedInterstitialAd ad) {
            _rewardedInterstitialAd = ad;
            _isLoading = false;
            _loadAttempt = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('RewardedInterstitialAd failed to load: $error');
            _rewardedInterstitialAd = null;
            _isLoading = false;
            _scheduleRetry();
          },
        ),
      );
    } catch (e) {
      debugPrint('RewardedInterstitialAd load exception: $e');
      _isLoading = false;
    }
  }

  void _scheduleRetry() {
    if (_loadAttempt >= _maxRetryAttempts) return;
    _loadAttempt += 1;
    final delaySeconds = 5 * _loadAttempt;
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      loadRewardedInterstitialAd();
    });
  }

  /// Displays a loaded rewarded interstitial ad.
  ///
  /// Returns `true` if the ad presentation flow started, or `false` if no ad
  /// was ready (in which case [onAdNotReady] is invoked and a reload begins).
  Future<bool> showRewardedInterstitialAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onAdClosed,
    VoidCallback? onAdNotReady,
  }) async {
    final ad = _rewardedInterstitialAd;
    if (ad == null) {
      _loadAttempt = 0;
      loadRewardedInterstitialAd();
      onAdNotReady?.call();
      return false;
    }

    _rewardedInterstitialAd = null;
    bool didInvokeClosed = false;

    void handleClosed() {
      if (didInvokeClosed) return;
      didInvokeClosed = true;
      onAdClosed?.call();
    }

    ad.fullScreenContentCallback =
        FullScreenContentCallback<RewardedInterstitialAd>(
      onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
        ad.dispose();
        handleClosed();
        loadRewardedInterstitialAd();
      },
      onAdFailedToShowFullScreenContent:
          (RewardedInterstitialAd ad, AdError error) {
        debugPrint('RewardedInterstitialAd failed to show: $error');
        ad.dispose();
        handleClosed();
        onAdNotReady?.call();
        loadRewardedInterstitialAd();
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onRewardEarned();
        },
      );
      return true;
    } catch (e) {
      debugPrint('RewardedInterstitialAd show exception: $e');
      ad.dispose();
      handleClosed();
      onAdNotReady?.call();
      loadRewardedInterstitialAd();
      return false;
    }
  }

  /// Disposes any cached ads and cancels pending retry timers.
  void dispose() {
    _interstitialRetryTimer?.cancel();
    _interstitialRetryTimer = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialLoading = false;

    _retryTimer?.cancel();
    _retryTimer = null;
    _rewardedInterstitialAd?.dispose();
    _rewardedInterstitialAd = null;
    _isLoading = false;
  }
}
