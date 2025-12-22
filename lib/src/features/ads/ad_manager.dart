import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdManager extends ChangeNotifier {
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

  // Use production ads (test ads removed for production)
  // Use kDebugMode to automatically switch
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

  bool _isBannerAdLoaded = false;
  bool _isRewardedAdLoading = false;
  bool _isInterstitialAdLoading = false;

  // Banner
  Future<void> loadBanner() async {
    // Dispose previous if any
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
    notifyListeners();

    BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner loaded');
          _bannerAd = ad as BannerAd;
          _isBannerAdLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          _isBannerAdLoaded = false;
          debugPrint('Banner failed to load: $error');
          notifyListeners();
          
          // Retry logic
           if (!useTestAds && error.code == 3) {
             Future.delayed(const Duration(seconds: 5), () => loadBanner());
           }
        },
      ),
    ).load();
  }

  BannerAd? get bannerAd => _isBannerAdLoaded ? _bannerAd : null;

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

  void showInterstitial({VoidCallback? onAdDismissed}) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitial(); // Reload next
          onAdDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          loadInterstitial();
          onAdDismissed?.call();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      loadInterstitial(); // Try load for next time
      onAdDismissed?.call();
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
      onAdNotReady?.call();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadRewarded();
        onAdDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        ad.dispose();
        loadRewarded();
        debugPrint('Rewarded ad failed to show: $err');
        onAdNotReady?.call();
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
      if (_isRewardedAdLoading) {
        debugPrint('Rewarded ad is loading, waiting...');
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (_rewardedAd != null) {
            _showRewardedAd(
              onReward,
              onAdDismissed: onAdDismissed,
              onAdNotReady: onAdNotReady,
            );
            return;
          }
        }
      }

      if (!_isRewardedAdLoading) {
        loadRewarded();
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
      onAdNotReady?.call();
    }
  }
}

final adManagerProvider = ChangeNotifierProvider<AdManager>((ref) {
  final manager = AdManager();
  // Don't auto-load here if we want to control it better, but initializing is fine
  manager.loadBanner();
  manager.loadInterstitial();
  manager.loadRewarded();
  return manager;
});
