/// Build-time environment configuration.
///
/// All values are injected via `--dart-define` flags so that secrets
/// never appear in version control:
///
/// ```sh
/// flutter build apk --release \
///   --dart-define=PRODUCTION=true \
///   --dart-define=ADMOB_APP_ID=ca-app-pub-XXXX~YYYY \
///   --dart-define=BANNER_AD_UNIT_ID=ca-app-pub-XXXX/ZZZZ \
///   --dart-define=INTERSTITIAL_AD_UNIT_ID=ca-app-pub-XXXX/WWWW
/// ```
abstract final class Env {
  // ─── Build mode ────────────────────────────────────────────────────

  /// `true` when compiled with `--dart-define=PRODUCTION=true`.
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );

  // ─── AdMob ─────────────────────────────────────────────────────────

  /// Test ad-unit IDs (Google-provided, safe to commit).
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testAdmobAppId =
      'ca-app-pub-3940256099942544~3347511713';

  /// Production ad-unit IDs injected at build time.
  static const String _prodBannerAdUnitId = String.fromEnvironment(
    'BANNER_AD_UNIT_ID',
  );
  static const String _prodInterstitialAdUnitId = String.fromEnvironment(
    'INTERSTITIAL_AD_UNIT_ID',
  );
  static const String _prodAdmobAppId = String.fromEnvironment('ADMOB_APP_ID');

  /// Resolved banner ad-unit ID (test or production).
  static String get bannerAdUnitId =>
      isProduction && _prodBannerAdUnitId.isNotEmpty
      ? _prodBannerAdUnitId
      : _testBannerAdUnitId;

  /// Resolved interstitial ad-unit ID (test or production).
  static String get interstitialAdUnitId =>
      isProduction && _prodInterstitialAdUnitId.isNotEmpty
      ? _prodInterstitialAdUnitId
      : _testInterstitialAdUnitId;

  /// Resolved AdMob app ID (test or production).
  static String get admobAppId => isProduction && _prodAdmobAppId.isNotEmpty
      ? _prodAdmobAppId
      : _testAdmobAppId;

  // ─── IAP ───────────────────────────────────────────────────────────

  /// Product ID for the "Remove Ads" non-consumable purchase.
  static const String removeAdsProductId = String.fromEnvironment(
    'REMOVE_ADS_PRODUCT_ID',
    defaultValue: 'remove_ads',
  );
}
