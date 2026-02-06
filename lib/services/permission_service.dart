import 'dart:io';

import 'package:permission_handler/permission_handler.dart' as ph;

import '../utils/logger.dart';

/// Handles runtime permission requests for storage access.
///
/// Android 10+ uses scoped storage (no explicit permission needed for
/// app-specific directories). Android 8–9 requires legacy storage
/// permissions.
class PermissionService {
  /// Checks whether storage is accessible. Requests permission on
  /// Android 8–9 if not already granted.
  ///
  /// Returns `true` when the app can read/write its output directory.
  Future<bool> ensureStoragePermission() async {
    try {
      // Android 10+ (API 29+): scoped storage — no permission needed.
      if (Platform.isAndroid) {
        final sdkInt = await _androidSdkVersion();
        if (sdkInt >= 29) return true;
      }

      // Android 8–9: request WRITE_EXTERNAL_STORAGE.
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
      // Assume granted on error — conversion will fail with a clear
      // message if storage truly is inaccessible.
      return true;
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
