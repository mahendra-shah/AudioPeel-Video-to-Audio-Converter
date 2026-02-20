import 'package:flutter/services.dart';

import '../utils/logger.dart';

/// Service to set an audio file as the device ringtone using a
/// platform channel.
class RingtoneService {
  static const _channel = MethodChannel('com.mcore.audiopeel/ringtone');

  /// Sets the audio file at [filePath] as the device ringtone.
  ///
  /// Returns `true` on success, `false` on failure.
  static Future<bool> setAsRingtone(String filePath) async {
    try {
      final result = await _channel.invokeMethod<bool>('setRingtone', {
        'filePath': filePath,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      Logger.error('Failed to set ringtone', error: e, tag: 'RingtoneService');
      return false;
    }
  }

  /// Checks whether the app has the WRITE_SETTINGS permission needed
  /// to modify system ringtone.
  static Future<bool> hasWriteSettingsPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('canWriteSettings');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system settings page where the user can grant the
  /// WRITE_SETTINGS permission.
  static Future<void> requestWriteSettings() async {
    try {
      await _channel.invokeMethod<void>('requestWriteSettings');
    } on PlatformException catch (e) {
      Logger.warning('Could not open write settings: $e', 'RingtoneService');
    }
  }
}
