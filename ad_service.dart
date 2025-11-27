import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdManager {
  InterstitialAdManager._();

  static final InterstitialAdManager instance = InterstitialAdManager._();

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;

  Future<void> preload() async {
    if (_interstitialAd != null || _isLoading) {
      return;
    }

    final String adUnitId = _adUnitId;
    if (adUnitId.isEmpty) {
      debugPrint('Interstitial ads are not supported on this platform.');
      return;
    }

    _isLoading = true;
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _isLoading = false;
          _interstitialAd = ad;
          debugPrint('Interstitial ad loaded successfully');
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Failed to load interstitial ad: $error');
          _isLoading = false;
        },
      ),
    );
  }

  void showAd({required VoidCallback onAdDismissed}) {
    if (_interstitialAd == null) {
      debugPrint('No interstitial ad available, preloading now...');
      onAdDismissed();
      unawaited(preload());
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('Interstitial ad dismissed');
        ad.dispose();
        _interstitialAd = null;
        onAdDismissed();
        unawaited(preload());
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('Failed to show interstitial ad: $error');
        ad.dispose();
        _interstitialAd = null;
        onAdDismissed();
        unawaited(preload());
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  String get _adUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ad unit ID
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ad unit ID
    }
    return '';
  }
}