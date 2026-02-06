/// All user-facing strings in one place for easy localisation.
///
/// Never hard-code UI text — reference these constants instead.
abstract final class AppStrings {
  // ─── App ────────────────────────────────────────────────────────────
  static const String appName = 'Voca: Video to Audio Converter';
  static const String appTagline = 'Video to Audio Converter';

  // ─── Home Screen ────────────────────────────────────────────────────
  static const String homeTitle = 'Voca';
  static const String homeSubtitle =
      'Convert videos to high-quality MP3 instantly';
  static const String selectVideo = 'SELECT VIDEO';
  static const String recentConversions = 'Recent Conversions';
  static const String seeAll = 'See all';
  static const String noConversionsYet = 'No conversions yet';
  static const String noConversionsDescription =
      'Select a video to start your first conversion';

  // ─── Conversion Options ─────────────────────────────────────────────
  static const String conversionOptions = 'Conversion Options';
  static const String videoPreview = 'Video Preview';
  static const String filename = 'Filename';
  static const String size = 'Size';
  static const String duration = 'Duration';
  static const String outputName = 'Output Name';
  static const String outputFileName = 'Output File Name';
  static const String audioQuality = 'Audio Quality (kbps)';
  static const String estimatedSize = 'Estimated Size';
  static const String estimatedTime = 'Estimated Time';
  static const String convertNow = 'CONVERT NOW';
  static const String startConversion = 'START CONVERSION';
  static const String fileNameHint = 'Enter output file name';
  static const String mp3Extension = '.mp3';

  // ─── Quality Labels ─────────────────────────────────────────────────
  static const String qualityLow = '128 kbps';
  static const String qualityLowLabel = 'Standard';
  static const String qualityMedium = '192 kbps';
  static const String qualityMediumLabel = 'High Quality';
  static const String qualityHigh = '320 kbps';
  static const String qualityHighLabel = 'Maximum';

  // ─── Converting Screen ──────────────────────────────────────────────
  static const String conversion = 'Conversion';
  static const String convertingStatus = 'CONVERTING...';
  static const String converting = 'Converting...';
  static const String convertingDescription =
      'Please wait while we extract the audio';
  static const String timeRemaining = 'Time Remaining:';
  static const String remaining = 'remaining';
  static const String cancel = 'CANCEL';
  static const String cancelConversion = 'Cancel Conversion?';
  static const String cancelConfirmation =
      'Are you sure you want to cancel the current conversion?';
  static const String yes = 'Yes';
  static const String no = 'No';

  // ─── Success Screen ─────────────────────────────────────────────────
  static const String conversionComplete = 'Conversion Complete!';
  static const String fileReady = 'Your file is ready to use';
  static const String preview = 'Preview';
  static const String fileNameLabel = 'FILE NAME';
  static const String savedToLabel = 'SAVED TO';
  static const String sizeLabel = 'SIZE';
  static const String play = 'PLAY';
  static const String shareFile = 'SHARE FILE';
  static const String share = 'SHARE';
  static const String delete = 'DELETE';
  static const String openFile = 'OPEN FILE';
  static const String convertAnother = 'CONVERT ANOTHER';
  static const String savedTo = 'Saved to';
  static const String deleteConfirmation =
      'Are you sure you want to delete this file?';

  // ─── Error Screen ───────────────────────────────────────────────────
  static const String conversionError = 'Conversion Error';
  static const String conversionFailed = 'Conversion Failed';
  static const String somethingWentWrong = 'Something went wrong';
  static const String errorDescription =
      'We encountered an issue while converting your '
      'video. The file may be corrupt or in an unsupported format. '
      'Please try a different video.';
  static const String retryConversion = 'Retry Conversion';
  static const String selectAnotherVideo = 'Select Another Video';
  static const String tryAgain = 'TRY AGAIN';
  static const String goBack = 'GO BACK';

  // ─── History Screen ─────────────────────────────────────────────────
  static const String conversionHistory = 'Conversion History';
  static const String history = 'History';
  static const String searchConvertedFiles = 'Search converted files';
  static const String allConversions = 'All';
  static const String todayFilter = 'Today';
  static const String last7Days = 'Last 7 Days';
  static const String highQualityFilter = 'High Quality';
  static const String today = 'TODAY';
  static const String yesterday = 'YESTERDAY';
  static const String last7DaysHeader = 'LAST 7 DAYS';
  static const String older = 'OLDER';
  static const String deleteConversion = 'Delete';
  static const String shareConversion = 'Share';
  static const String clearAllHistory = 'Clear All';
  static const String clearHistoryConfirmation =
      'Are you sure you want to clear all conversion history?';
  static const String searchHistory = 'Search conversions...';
  static const String noHistoryYet = 'No conversions yet';
  static const String noHistoryDescription =
      'Your converted files will appear here';

  // ─── Settings Screen ────────────────────────────────────────────────
  static const String settings = 'Settings';
  static const String audioSettings = 'AUDIO SETTINGS';
  static const String audioQualityLabel = 'Audio Quality';
  static const String normalizeVolume = 'Normalize Volume';
  static const String appearanceAndBehavior = 'APPEARANCE & BEHAVIOR';
  static const String appearance = 'Appearance';
  static const String darkMode = 'Dark Mode';
  static const String autoDeleteOriginal = 'Auto-delete Original';
  static const String autoDeleteDescription = 'Delete video after conversion';
  static const String defaultQuality = 'Default Quality';
  static const String storage = 'STORAGE';
  static const String outputPath = 'Output Path';
  static const String outputLocation = 'Output Location';
  static const String clearCache = 'Clear Cache';
  static const String cacheCleared = 'Cache cleared';
  static const String about = 'ABOUT';
  static const String appNameAbout = 'Voca';
  static const String version = 'Version';
  static const String versionValue = 'v1.0.0 (Build 1)';
  static const String copyright = 'Voca © 2026';
  static const String rateApp = 'Rate App';
  static const String shareApp = 'Share App';
  static const String privacyPolicy = 'Privacy Policy';
  static const String removeAds = 'Remove Ads';
  static const String removeAdsPrice = '\$1.99';
  static const String removeAdsDescription =
      'One-time purchase to remove all advertisements';
  static const String adsRemoved = 'Ads Removed';
  static const String selectQuality = 'Select Quality';

  // ─── Splash Screen ──────────────────────────────────────────────────
  static const String splashTagline = 'Extract Audio in Seconds';
  static const String badgeOffline = 'Offline';
  static const String badgeFree = 'Free';
  static const String badgeNoAccount = 'No Account';

  // ─── Permissions ────────────────────────────────────────────────────
  static const String storagePermissionRequired =
      'Storage permission is required to save MP3 files';
  static const String grantPermission = 'GRANT PERMISSION';
  static const String permissionDenied = 'Permission Denied';
  static const String openSettings = 'OPEN SETTINGS';

  // ─── Generic ────────────────────────────────────────────────────────
  static const String ok = 'OK';
  static const String done = 'Done';
  static const String close = 'Close';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String retry = 'Retry';
}
