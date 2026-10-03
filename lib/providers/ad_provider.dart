import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// Ad loading and frequency rules.
///
/// Rules (retention first):
/// * nothing until UMP consent allows ads ([enable]);
/// * no interstitial during the first [graceConversions] successes;
/// * afterwards at most every [AppConstants.interstitialAdFrequency]th
///   result, and only when the user *leaves* the result screen.
class AdProvider extends ChangeNotifier {
  static const int graceConversions = 3;

  bool _enabled = false;
  int _exitsSinceAd = 0;
  InterstitialAd? _interstitialAd;

  /// Whether ads may be requested (consent resolved).
  bool get enabled => _enabled;

  /// Called once consent allows ads and the SDK is initialised.
  void enable() {
    if (_enabled) return;
    _enabled = true;
    notifyListeners();
    loadInterstitial();
  }

  void loadInterstitial() {
    if (!_enabled || _interstitialAd != null) return;
    InterstitialAd.load(
      adUnitId: Env.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => Logger.warning(
          'Interstitial failed to load: ${error.message}',
          'AdProvider',
        ),
      ),
    );
  }

  /// Call when the user leaves a finished result. May show an interstitial.
  Future<void> onResultExit() async {
    if (!_enabled) return;
    final prefs = await SharedPreferences.getInstance();
    final successes = prefs.getInt(AppConstants.prefTotalConversions) ?? 0;
    if (successes <= graceConversions) return;

    _exitsSinceAd++;
    if (_exitsSinceAd < AppConstants.interstitialAdFrequency) return;

    final ad = _interstitialAd;
    if (ad == null) {
      loadInterstitial();
      return;
    }
    _interstitialAd = null;
    _exitsSinceAd = 0;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        loadInterstitial();
      },
    );
    await ad.show();
  }

  BannerAd createBannerAd({required void Function() onLoaded}) {
    return BannerAd(
      adUnitId: Env.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
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
