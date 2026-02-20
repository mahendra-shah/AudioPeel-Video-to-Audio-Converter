import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/env.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// Manages ad loading, display, and frequency gating.
class AdProvider extends ChangeNotifier {
  int _conversionCount = 0;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;

  /// Whether an interstitial ad is loaded and ready to show.
  bool get isInterstitialReady => _isInterstitialReady;

  /// Preloads an interstitial ad.
  void loadInterstitial() {

    InterstitialAd.load(
      adUnitId: Env.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          Logger.debug('Interstitial ad loaded', 'AdProvider');
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _isInterstitialReady = false;
          Logger.warning(
            'Interstitial failed to load: ${error.message}',
            'AdProvider',
          );
        },
      ),
    );
  }

  /// Shows the interstitial ad if it is ready and the conversion count
  /// has reached the configured frequency.
  ///
  /// Returns `true` if an ad was shown.
  Future<bool> showInterstitialIfReady() async {
    _conversionCount++;

    if (_conversionCount % AppConstants.interstitialAdFrequency != 0) {
      return false;
    }

    if (!_isInterstitialReady || _interstitialAd == null) {
      loadInterstitial();
      return false;
    }

    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialReady = false;
          loadInterstitial(); // Pre-load next one.
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          Logger.warning('Interstitial failed to show: ${error.message}', 'Ad');
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialReady = false;
          loadInterstitial();
        },
      );

      await _interstitialAd!.show();
      return true;
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to show interstitial',
        error: e,
        stackTrace: st,
        tag: 'AdProvider',
      );
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _isInterstitialReady = false;
      loadInterstitial();
      return false;
    }
  }

  /// Creates a banner ad widget-ready [BannerAd].
  BannerAd? createBannerAd() {
    return BannerAd(
      adUnitId: Env.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => Logger.debug('Banner loaded', 'AdProvider'),
        onAdFailedToLoad: (ad, error) {
          Logger.warning('Banner failed: ${error.message}', 'AdProvider');
          ad.dispose();
        },
      ),
    );
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }
}
