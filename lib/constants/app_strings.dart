/// All user-facing strings in one place for easy localisation.
abstract final class AppStrings {
  // ─── Identity ───────────────────────────────────────────────────────
  static const String appName = 'AudioPeel';
  static const String appTagline = 'Extract audio from any video';

  // ─── General ────────────────────────────────────────────────────────
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String confirm = 'Confirm';
  static const String undo = 'Undo';
  static const String done = 'Done';
  static const String share = 'Share';
  static const String open = 'Open';
  static const String retry = 'Retry';
  static const String save = 'Save';
  static const String close = 'Close';
  static const String back = 'Back';
  static const String continueLabel = 'Continue';
  static const String selectAll = 'Select All';
  static const String clearAll = 'Clear All';

  // ─── Navigation ─────────────────────────────────────────────────────
  static const String navHome = 'Home';
  static const String navStudio = 'Studio';
  static const String navLibrary = 'Library';
  static const String navSettings = 'Settings';

  // ─── Home screen ────────────────────────────────────────────────────
  static const String homePickCta = 'Pick a Video';
  static const String homePickMultipleCta = 'Pick Multiple Videos';
  static const String homeRecentHeading = 'Recent';
  static const String homeNoRecent = 'Your converted audio will appear here.';
  static const String homeShareHint =
      'Tip: Share any video from your gallery to AudioPeel.';
  static const String homeSupportedFormats =
      'MP4 · MKV · AVI · MOV · WebM · and more';
  static const String homeTipDismiss = 'Got it';

  // ─── Studio screen ───────────────────────────────────────────────────
  static const String studioTitle = 'Studio';
  static const String studioConvertCta = 'Convert';
  static const String studioConvertCtaBatch = 'Convert All';
  static const String studioFormatSection = 'Format';
  static const String studioQualitySection = 'Quality';
  static const String studioTrimSection = 'Trim';
  static const String studioEnhanceSection = 'Enhance';
  static const String studioMetaSection = 'Metadata';
  static const String studioFileNameLabel = 'File name';
  static const String studioFileNameHint = 'Leave blank to use video name';
  static const String studioTitleLabel = 'Title tag';
  static const String studioArtistLabel = 'Artist tag';
  static const String studioTagHint = 'Optional';
  static const String studioNormalizeLabel = 'Normalize volume';
  static const String studioNormalizeHint =
      'Adjusts loudness to a consistent level';
  static const String studioAlbumArtLabel = 'Embed cover art';
  static const String studioAlbumArtHint = 'Attaches a video frame to MP3';
  static const String studioFadeInLabel = 'Fade in';
  static const String studioFadeOutLabel = 'Fade out';
  static const String studioVolumeLabel = 'Volume boost';
  static const String studioEstSize = 'Est. size';
  static const String studioTrimStart = 'Start';
  static const String studioTrimEnd = 'End';
  static const String studioTrimDuration = 'Duration';
  static const String studioStreamCopyBadge = 'Instant copy';
  static const String studioStreamCopyTip =
      'This M4A will be copied directly — no re-encoding, instant and lossless.';
  static const String studioBatchSuffix = 'videos selected';
  static const String studioAddMore = 'Add More';

  // ─── Job / progress screen ───────────────────────────────────────────
  static const String jobTitle = 'Converting';
  static const String jobTitleDone = 'Done!';
  static const String jobTitleFailed = 'Failed';
  static const String jobTitleCancelled = 'Cancelled';
  static const String jobStatusQueued = 'Queued';
  static const String jobStatusRunning = 'Converting…';
  static const String jobStatusDone = 'Saved to Music';
  static const String jobStatusFailed = 'Failed';
  static const String jobStatusCancelled = 'Cancelled';
  static const String jobCancelCta = 'Cancel';
  static const String jobDoneCta = 'Done';
  static const String jobShareCta = 'Share';
  static const String jobOpenCta = 'Open File';
  static const String jobSetRingtoneCta = 'Set as Ringtone';
  static const String jobOverallProgress = 'Overall progress';
  static const String jobEta = 'ETA';
  static const String jobCalculating = 'Calculating…';
  static const String jobSavedTo = 'Saved to';
  static const String jobAllDone = 'All conversions complete';
  static const String jobSomeFailed = 'Some conversions failed';

  // ─── Ringtone ────────────────────────────────────────────────────────
  static const String ringtoneSheetTitle = 'Set as…';
  static const String ringtoneOptionRingtone = 'Ringtone';
  static const String ringtoneOptionNotification = 'Notification sound';
  static const String ringtoneOptionAlarm = 'Alarm';
  static const String ringtonePermissionRequired =
      'Write Settings permission is needed.';
  static const String ringtonePermissionCta = 'Grant Permission';
  static const String ringtoneSuccess = 'Ringtone set!';
  static const String ringtoneFailed = 'Could not set ringtone.';

  // ─── Errors & warnings ───────────────────────────────────────────────
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNoAudio = "This video doesn't have a sound track.";
  static const String errorStoragePermission =
      'Storage permission is needed to save to Music.';
  static const String errorLowStorage =
      'Not enough storage space. Free up at least 50 MB and try again.';
  static const String errorUnsupportedFile =
      'This file type is not supported.';
  static const String errorFileMissing =
      'The source file could not be found.';

  // ─── Accessibility ───────────────────────────────────────────────────
  static const String a11yPickVideo = 'Pick video to convert';
  static const String a11yDeleteEntry = 'Delete conversion entry';
  static const String a11yShareFile = 'Share audio file';
  static const String a11yProgressBar = 'Conversion progress';

  // ─── Library ────────────────────────────────────────────────────────
  static const String libraryTitle = 'Library';
  static const String librarySearchHint = 'Search conversions…';
  static const String libraryEmptyTitle = 'No conversions yet';
  static const String libraryEmptySubtitle = 'Tap Convert to begin';
  static const String libraryGroupToday = 'Today';
  static const String libraryGroupYesterday = 'Yesterday';
  static const String libraryGroupThisWeek = 'This week';
  static const String libraryGroupOlder = 'Older';
  static const String libraryActionPlay = 'Play';
  static const String libraryActionShare = 'Share';
  static const String libraryActionRingtone = 'Set as ringtone';
  static const String libraryActionOpenWith = 'Open with';
  static const String libraryActionDelete = 'Delete';
  static const String libraryDeletedSnackbar = 'Conversion deleted';
  static const String libraryUndoLabel = 'Undo';

  // ─── Settings ───────────────────────────────────────────────────────
  static const String settingsTitle = 'Settings';

  // Defaults section
  static const String settingsSectionDefaults = 'Conversion Defaults';
  static const String settingsFormat = 'Format';
  static const String settingsQuality = 'Quality';
  static const String settingsNormalizeVolume = 'Normalize volume';
  static const String settingsNormalizeVolumeSubtitle =
      'Level out loud and quiet parts';
  static const String settingsAlbumArt = 'Embed album art';
  static const String settingsAlbumArtSubtitle = 'Attach artwork from video';

  // Appearance section
  static const String settingsSectionAppearance = 'Appearance';
  static const String settingsTheme = 'Theme';
  static const String settingsThemeSystem = 'System';
  static const String settingsThemeLight = 'Light';
  static const String settingsThemeDark = 'Dark';

  // Storage section
  static const String settingsSectionStorage = 'Storage';
  static const String settingsSavedTo = 'Saved to';
  static const String settingsOpenFolder = 'Open folder';
  static const String settingsClearCache = 'Clear temporary files';
  static const String settingsClearCacheConfirmTitle = 'Clear cache?';
  static const String settingsClearCacheConfirmBody =
      'This removes temporary processing files. Your converted audio is safe.';
  static const String settingsClearCacheSuccess = 'Cache cleared';

  // About section
  static const String settingsSectionAbout = 'About';
  static const String settingsRate = 'Rate AudioPeel';
  static const String settingsShareApp = 'Share AudioPeel';
  static const String settingsPrivacyPolicy = 'Privacy Policy';
  static const String settingsPrivacyOptions = 'Privacy options';
  static const String settingsVersion = 'Version';

  // URLs
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.mcore.audiopeel';
  static const String privacyPolicyUrl =
      'https://audiopeel.app/privacy';
}
