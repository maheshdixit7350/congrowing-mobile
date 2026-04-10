import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AdManager {
  static InterstitialAd? _interstitialAd;
  static bool _isLoaded = false;

  // ── Ad Unit IDs (Production) ────────────────────────────────────────────
  // Interstitial: shown between call connect & before connecting
  static const String interstitialAdUnitId = 'ca-app-pub-4530412678462174/2088929751';
  // Banner: shown at the bottom of screens
  static const String bannerAdUnitId = 'ca-app-pub-4530412678462174/5805016742';

  // ── Interstitial Ads ────────────────────────────────────────────────────
  static void loadInterstitialAd() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoaded = true;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isLoaded = false;
              loadInterstitialAd(); // Preload next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isLoaded = false;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          _isLoaded = false;
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), () => loadInterstitialAd());
        },
      ),
    );
  }

  /// Show interstitial then run callback. Always runs callback.
  static void showInterstitialAd(void Function() onComplete) {
    if (_isLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isLoaded = false;
          loadInterstitialAd();
          onComplete();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isLoaded = false;
          loadInterstitialAd();
          onComplete();
        },
      );
      _interstitialAd!.show();
    } else {
      onComplete(); // If ad not loaded, still proceed
    }
  }
}
