import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdService {
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  // Test Ad Unit ID for Interstitial (for development)
  static const String testInterstitialAdUnitIdAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String testInterstitialAdUnitIdIOS =
      'ca-app-pub-3940256099942544/4411468910';

  // Production Ad Unit ID for Interstitial
  static const String productionInterstitialAdUnitId =
      'ca-app-pub-9698718721404755/4637083696';

  // Use production ads (test ads removed for production)
  static bool get useTestAds => false;

  String get _adUnitId {
    if (useTestAds) {
      // Test ads (not used in production)
      if (Platform.isAndroid) {
        return testInterstitialAdUnitIdAndroid;
      } else if (Platform.isIOS) {
        return testInterstitialAdUnitIdIOS;
      } else {
        return '';
      }
    } else {
      // Production ads - always used now
      return productionInterstitialAdUnitId;
    }
  }

  Future<void> init() async {
    await MobileAds.instance.initialize();
    loadInterstitialAd();
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
      // Override the callback to call our passed callback
      // We need to chain the existing callback logic if we want to reload,
      // but the callback is set on the ad object.
      // Wait, we set the callback when loading.
      // But we want to trigger something SPECIFIC this time (like navigating to next question).
      // So we should hook into the dismiss.

      // Let's wrap the callback or just accept that "onAdDismissedFullScreenContent" handles the disposal and reloading.
      // But we need to define WHAT happens on dismiss for the GAME flow.

      // Better approach:
      // When showing, set the callback OR return a specific future?
      // FullScreenContentCallback doesn't return future.

      // Let's clear the old callback and set a new one that calls the original logic + user logic.
      // Or simplier: just use a completion callback passed here.

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
}

final adService = AdService();
