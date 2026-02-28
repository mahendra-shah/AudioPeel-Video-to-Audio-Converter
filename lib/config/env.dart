/// Build-time environment configuration.
///
/// Pass `--dart-define=PRODUCTION=true` to activate production ad IDs:
/// ```sh
/// flutter build appbundle --release --dart-define=PRODUCTION=true
/// ```
/// The AdMob App ID is read directly from AndroidManifest.xml by the SDK
/// and does not need to be passed here.
abstract final class Env {
  // ─── Build mode ────────────────────────────────────────────────────

  /// `true` when compiled with `--dart-define=PRODUCTION=true`.
  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );

  // ─── AdMob ad-unit IDs ─────────────────────────────────────────────

  /// Google-provided test IDs — safe to commit, never charge real users.
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  /// Production ad-unit IDs.
  static const String _prodBannerAdUnitId = String.fromEnvironment(
    'BANNER_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-5583038215571668/8873333176',
  );
  static const String _prodInterstitialAdUnitId = String.fromEnvironment(
    'INTERSTITIAL_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-5583038215571668/1367114336',
  );

  /// Resolved banner ad-unit ID (test in debug/profile, production in release).
  static String get bannerAdUnitId =>
      isProduction ? _prodBannerAdUnitId : _testBannerAdUnitId;

  /// Resolved interstitial ad-unit ID (test in debug/profile, production in release).
  static String get interstitialAdUnitId =>
      isProduction ? _prodInterstitialAdUnitId : _testInterstitialAdUnitId;
}
