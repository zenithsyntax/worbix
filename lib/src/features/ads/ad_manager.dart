import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdManager {
  // Test Ad Unit IDs (for development)
  static const String testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // Production Ad Unit IDs
  static const String bannerAdUnitId =
      'ca-app-pub-9698718721404755/6442502844'; // Banner ad
  static const String interstitialAdUnitId =
      'ca-app-pub-9698718721404755/4637083696'; // Interstitial ad
  static const String rewardedAdUnitId =
      'ca-app-pub-9698718721404755/8520488387'; // Hint rewarded ad

  // Use test ads in debug mode or when production ads fail
  static bool get useTestAds => kDebugMode;

  String get _bannerAdUnitId =>
      useTestAds ? testBannerAdUnitId : bannerAdUnitId;
  String get _interstitialAdUnitId =>
      useTestAds ? testInterstitialAdUnitId : interstitialAdUnitId;
  String get _rewardedAdUnitId =>
      useTestAds ? testRewardedAdUnitId : rewardedAdUnitId;

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isRewardedAdLoading = false;
  bool _isInterstitialAdLoading = false;

  // Banner
  Future<void> loadBanner() async {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => debugPrint('Banner loaded'),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner failed to load: $error');
          // Retry after delay if using production ads
          if (!useTestAds && error.code == 3) {
            Future.delayed(const Duration(seconds: 5), () => loadBanner());
          }
        },
      ),
    );
    await _bannerAd?.load();
  }

  BannerAd? get bannerAd => _bannerAd;

  // Interstitial
  void loadInterstitial() {
    if (_isInterstitialAdLoading) return;
    _isInterstitialAdLoading = true;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          debugPrint('Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoading = false;
          debugPrint('Interstitial failed: $error');
          // Retry after delay if using production ads
          if (!useTestAds && error.code == 3) {
            Future.delayed(
              const Duration(seconds: 5),
              () => loadInterstitial(),
            );
          }
        },
      ),
    );
  }

  void showInterstitial() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitial(); // Reload next
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          loadInterstitial();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      loadInterstitial(); // Try load for next time
    }
  }

  // Rewarded
  void loadRewarded() {
    if (_isRewardedAdLoading) return;
    _isRewardedAdLoading = true;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          debugPrint('Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoading = false;
          debugPrint(
            'Rewarded failed: $error - Code: ${error.code}, Message: ${error.message}',
          );
          // Retry after delay for network errors or other retryable errors
          // Error code 3 = ERROR_CODE_NO_FILL, but we should retry for other errors too
          if (error.code == 3 || error.code == 0 || error.code == 2) {
            Future.delayed(const Duration(seconds: 3), () => loadRewarded());
          }
        },
      ),
    );
  }

  void _showRewardedAd(
    Function(RewardItem) onReward, {
    Function()? onAdDismissed,
    Function()? onAdNotReady,
  }) {
    if (_rewardedAd == null) {
      if (onAdNotReady != null) {
        onAdNotReady();
      }
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewarded();
        // When ad is dismissed, user watched it - trigger callback
        if (onAdDismissed != null) {
          onAdDismissed();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        loadRewarded();
        debugPrint('Rewarded ad failed to show: $err');
        // If ad fails to show, call the fallback
        if (onAdNotReady != null) {
          onAdNotReady();
        }
      },
    );
    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onReward(reward);
      },
    );
    _rewardedAd = null;
  }

  Future<void> showRewarded(
    Function(RewardItem) onReward, {
    Function()? onAdDismissed,
    Function()? onAdNotReady,
  }) async {
    if (_rewardedAd != null) {
      _showRewardedAd(
        onReward,
        onAdDismissed: onAdDismissed,
        onAdNotReady: onAdNotReady,
      );
    } else {
      // If ad is loading, wait a bit and check again
      if (_isRewardedAdLoading) {
        debugPrint('Rewarded ad is loading, waiting...');
        // Wait up to 5 seconds for the ad to load (increased from 3 seconds)
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (_rewardedAd != null) {
            // Ad loaded, show it
            _showRewardedAd(
              onReward,
              onAdDismissed: onAdDismissed,
              onAdNotReady: onAdNotReady,
            );
            return;
          }
        }
      }

      // Try to load if not already loading
      if (!_isRewardedAdLoading) {
        loadRewarded();
        // Wait a bit more after triggering load
        await Future.delayed(const Duration(seconds: 2));
        if (_rewardedAd != null) {
          _showRewardedAd(
            onReward,
            onAdDismissed: onAdDismissed,
            onAdNotReady: onAdNotReady,
          );
          return;
        }
      }

      debugPrint('Rewarded ad not ready after waiting');
      // If ad is not ready, call the fallback callback
      if (onAdNotReady != null) {
        onAdNotReady();
      }
    }
  }
}

final adManagerProvider = Provider<AdManager>((ref) {
  final manager = AdManager();
  manager.loadBanner();
  manager.loadInterstitial();
  manager.loadRewarded();
  return manager;
});
