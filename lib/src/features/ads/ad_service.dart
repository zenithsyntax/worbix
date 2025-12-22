import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdService {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  // Test Ad Unit ID for Interstitial (for development)
  // Test Ad Unit ID for Interstitial (for development)
  static const String testInterstitialAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testInterstitialAdUnitIdIOS =
      'ca-app-pub-3940256099942544/4411468910';

  // Production Ad Unit ID for Interstitial
  static const String productionInterstitialAdUnitId =
      'ca-app-pub-9698718721404755/4637083696';

  // Test Ad Unit ID for Rewarded (for development)
  static const String testRewardedAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String testRewardedAdUnitIdIOS =
      'ca-app-pub-3940256099942544/1712485313';

  // Production Ad Unit ID for Rewarded
  static const String productionRewardedAdUnitId =
      'ca-app-pub-9698718721404755/8520488387';

  // Use production ads (test ads removed for production)
  static bool get useTestAds => false;

  String get _adUnitId {
    if (useTestAds) {
      if (Platform.isAndroid) {
        return testInterstitialAdUnitIdAndroid;
      } else if (Platform.isIOS) {
        return testInterstitialAdUnitIdIOS;
      } else {
        return '';
      }
    } else {
      return productionInterstitialAdUnitId;
    }
  }

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  String get _rewardedAdUnitId {
    if (useTestAds) {
      if (Platform.isAndroid) {
        return testRewardedAdUnitIdAndroid;
      } else if (Platform.isIOS) {
        return testRewardedAdUnitIdIOS;
      } else {
        return '';
      }
    } else {
      return productionRewardedAdUnitId;
    }
  }

  Future<void> init() async {
    await MobileAds.instance.initialize();
    loadInterstitialAd();
    loadRewardedAd();
  }

  void loadInterstitialAd() {
    if (_adUnitId.isEmpty) return; // Not supported on other platforms

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  // Load next ad
                  loadInterstitialAd();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  debugPrint('Ad failed to show: $error');
                  ad.dispose();
                  loadInterstitialAd();
                },
              );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Ad failed to load: $error');
          _isAdLoaded = false;
        },
      ),
    );
  }

  void showInterstitialAd({required VoidCallback onAdDismissed}) {
    if (_isAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          onAdDismissed();
          ad.dispose();
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          debugPrint('Failed to show ad: $err');
          onAdDismissed(); // Proceed anyway
          ad.dispose();
          loadInterstitialAd();
        },
      );

      _interstitialAd!.show();
      _interstitialAd = null;
      _isAdLoaded = false;
    } else {
      // If not loaded, proceed immediately
      onAdDismissed();
      // Try loading again for next time
      loadInterstitialAd();
    }
  }

  void loadRewardedAd() {
    if (_rewardedAdUnitId.isEmpty) return;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _isRewardedAdLoaded = false;
        },
      ),
    );
  }

  void showRewardedAd(
    Function(RewardItem) onUserEarnedReward, {
    VoidCallback? onAdNotReady,
  }) {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          loadRewardedAd();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onUserEarnedReward(reward);
        },
      );
      _rewardedAd = null;
      _isRewardedAdLoaded = false;
    } else {
      onAdNotReady?.call();
      loadRewardedAd();
    }
  }
}

final adService = AdService();
