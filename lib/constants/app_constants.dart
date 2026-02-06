/// Application-wide constants — ad config, quality defaults, sizing, etc.
///
/// No magic numbers should exist outside this file.
abstract final class AppConstants {
  // ─── Ad Configuration ───────────────────────────────────────────────

  /// Number of conversions between interstitial ads.
  static const int interstitialAdFrequency = 1;

  // ─── IAP ────────────────────────────────────────────────────────────

  /// Product ID for the "Remove Ads" non-consumable purchase.
  static const String removeAdsProductId = 'remove_ads';

  // ─── Audio Quality Defaults ─────────────────────────────────────────

  /// Default audio bitrate in kbps.
  static const int defaultQualityKbps = 192;

  /// Audio sample rate in Hz (CD quality).
  static const int audioSampleRate = 44100;

  /// Number of audio channels (stereo).
  static const int audioChannels = 2;

  // ─── File Constraints ───────────────────────────────────────────────

  /// Maximum allowed file name length.
  static const int maxFileNameLength = 50;

  /// Default output sub-directory inside app's external storage.
  static const String outputDirectoryName = 'MP3Extract';

  /// Supported video extensions for file picker.
  static const List<String> supportedVideoExtensions = [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'wmv',
    'flv',
    'webm',
    '3gp',
    'ts',
    'm4v',
  ];

  // ─── UI Sizing ──────────────────────────────────────────────────────

  /// Standard screen / card horizontal padding.
  static const double paddingScreen = 16.0;

  /// Spacing between major sections.
  static const double spacingSection = 24.0;

  /// Spacing between related elements.
  static const double spacingElement = 16.0;

  /// Spacing between small items (chips, tags).
  static const double spacingSmall = 8.0;

  /// Tiny spacing (icon-to-text gap, inner chip padding).
  static const double spacingTiny = 4.0;

  /// Standard card corner radius.
  static const double cardRadius = 16.0;

  /// Standard button corner radius.
  static const double buttonRadius = 12.0;

  /// Standard button height.
  static const double buttonHeight = 52.0;

  // ─── Conversion Limits ────────────────────────────────────────────

  /// Maximum conversion time before automatic cancellation.
  static const Duration conversionTimeout = Duration(minutes: 10);

  /// Minimum free disk space in bytes required to start a conversion
  /// (~50 MB).
  static const int minimumFreeSpaceBytes = 50 * 1024 * 1024;

  // ─── Search ─────────────────────────────────────────────────────────

  /// Debounce duration for the history search field.
  static const Duration searchDebounceDuration = Duration(milliseconds: 300);

  // ─── Animation ──────────────────────────────────────────────────────

  /// Default animation duration.
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// Fast animation duration (e.g. icon swap).
  static const Duration animationFast = Duration(milliseconds: 150);

  // ─── Database ───────────────────────────────────────────────────────

  /// SQLite database file name.
  static const String databaseName = 'mp3_extract.db';

  /// Current database version for migrations.
  static const int databaseVersion = 1;

  // ─── Preferences Keys ──────────────────────────────────────────────

  /// SharedPreferences key for dark mode toggle.
  static const String prefDarkMode = 'dark_mode';

  /// SharedPreferences key for default quality (kbps integer).
  static const String prefDefaultQuality = 'default_quality';

  /// SharedPreferences key for ads-removed flag.
  static const String prefAdsRemoved = 'ads_removed';

  /// SharedPreferences key for total conversions counter.
  static const String prefTotalConversions = 'total_conversions';
}
