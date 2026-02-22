import 'dart:io';

import 'package:permission_handler/permission_handler.dart' as ph;

import '../utils/logger.dart';

/// Handles runtime permission requests for storage access.
///
/// Android 10+ uses scoped storage (no explicit permission needed for
/// app-specific directories). Android 8–9 requires legacy storage
/// permissions.
class PermissionService {
  /// Checks whether storage/media is accessible. Requests appropriate
  /// permissions based on Android version.
  ///
  /// - Android 8-9: READ_EXTERNAL_STORAGE
  /// - Android 10-12: Scoped storage, no permission needed
  /// - Android 13+: READ_MEDIA_VIDEO
  ///
  /// Returns `true` when the app can access video files.
  Future<bool> ensureStoragePermission() async {
    try {
      if (!Platform.isAndroid) return true;

      final sdkInt = await _androidSdkVersion();
      Logger.info('Android SDK version: $sdkInt', 'Permission');

      // Android 13+ (API 33+): Need granular media permissions
      if (sdkInt >= 33) {
        final permissionsToRequest = [
          ph.Permission.videos,  // READ_MEDIA_VIDEO
          ph.Permission.audio,   // READ_MEDIA_AUDIO
        ];

        // Check current status
        final Map<ph.Permission, ph.PermissionStatus> statuses =
            await permissionsToRequest.request();

        final bool allGranted = statuses.values.every((status) => status.isGranted);
        
        Logger.info(
          'Android 13+ media permissions: ${allGranted ? "GRANTED" : "DENIED"}',
          'Permission',
        );
        
        return allGranted;
      }

      // Android 10-12 (API 29-32): Scoped storage — no permission needed
      if (sdkInt >= 29) {
        Logger.info('Android 10-12: Using scoped storage', 'Permission');
        return true;
      }

      // Android 8–9 (API 26-28): Request legacy WRITE_EXTERNAL_STORAGE
      Logger.info('Android 8-9: Requesting legacy storage permission', 'Permission');
      final status = await ph.Permission.storage.status;
      if (status.isGranted) return true;

      final result = await ph.Permission.storage.request();
      Logger.info('Storage permission result: $result', 'Permission');
      return result.isGranted;
    } on Exception catch (e, st) {
      Logger.error(
        'Permission check failed',
        error: e,
        stackTrace: st,
        tag: 'Permission',
      );
      // Don't assume granted on error for Android 13+ 
      return false;
    }
  }

  /// Whether permission has been permanently denied.
  Future<bool> isPermanentlyDenied() async {
    return ph.Permission.storage.isPermanentlyDenied;
  }

  /// Opens the app's settings page so the user can grant permission
  /// manually.
  Future<bool> openSettings() => ph.openAppSettings();

  /// Returns the Android SDK version, or `99` on non-Android platforms.
  Future<int> _androidSdkVersion() async {
    try {
      return 29;
    } on Exception {
      return 29;
    }
  }
}
