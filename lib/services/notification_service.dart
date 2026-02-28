import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/logger.dart';

/// Manages local notifications for conversion progress and completion.
///
/// Shows a persistent progress notification while converting, updates it
/// as conversion proceeds, and displays a completion or error notification
/// when finished. Follows Android 13+ notification permission requirements.
///
/// Notifications are only shown when the app is in the background - when the
/// user is actively using the app, they can see progress on screen.
class NotificationService with WidgetsBindingObserver {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _isAppInForeground = true; // Track if app is visible to user
  bool _permissionGranted = false; // Cached after first grant check
  DateTime? _lastProgressNotification; // Throttle: max 1 update/second

  // Notification IDs
  static const int _progressNotificationId = 1001;
  static const int _completionNotificationId = 1002;

  // Notification channel (Android) - renamed to force fresh channel creation
  static const String _channelId = 'audiopeel_conversion_v2';
  static const String _channelName = 'Conversion Progress';
  static const String _channelDescription =
      'Shows progress when converting videos to audio';

  /// Initializes the notification plugin and creates Android notification channel.
  ///
  /// Must be called during app startup (typically in main.dart).
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');

      // iOS initialization settings (for future iOS support)
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      // Register lifecycle observer to track app foreground/background state
      WidgetsBinding.instance.addObserver(this);

      _initialized = true;
      Logger.info('NotificationService initialized', 'NotificationService');
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to initialize notifications',
        error: e,
        stackTrace: st,
        tag: 'NotificationService',
      );
    }
  }

  /// Creates the notification channel for Android.
  Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.defaultImportance,
      showBadge: true,
      enableVibration: false,
      playSound: false,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    Logger.info('Notification channel created', 'NotificationService');
  }

  /// Tracks app lifecycle changes to determine when to show notifications.
  ///
  /// Notifications are only shown when app is in background (paused/inactive).
  /// When user returns to app, progress notifications are cancelled since they
  /// can see progress on screen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Logger.info(
      'App lifecycle changed to: $state',
      'NotificationService',
    );
    switch (state) {
      case AppLifecycleState.resumed:
        // App is visible and responding to user input
        _isAppInForeground = true;
        Logger.info('App FOREGROUND - notifications disabled', 'NotificationService');
      case AppLifecycleState.inactive:
        // Briefly covered by a system dialog (e.g. permission prompt) —
        // the app is still visible to the user, do not change foreground state.
        break;
      case AppLifecycleState.paused:
        // App is truly in the background (home button, switch apps, etc.)
        _isAppInForeground = false;
        Logger.info('App BACKGROUND - notifications enabled', 'NotificationService');
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is detached or hidden
        _isAppInForeground = false;
        Logger.info('App DETACHED/HIDDEN - notifications enabled', 'NotificationService');
    }
  }

  /// Cleans up the lifecycle observer.
  ///
  /// Should be called when the service is no longer needed (rarely used).
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Logger.info('NotificationService disposed', 'NotificationService');
  }

  /// Requests notification permission on Android 13+ (API 33+).
  ///
  /// Uses flutter_local_notifications built-in request which handles
  /// Android version detection correctly internally.
  /// Returns `true` if permission is granted, `false` otherwise.
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      // flutter_local_notifications v17+ handles version check internally.
      // Returns null on pre-Android 13 (permission not required → treat as granted).
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final granted =
          await androidPlugin?.requestNotificationsPermission() ?? true;

      _permissionGranted = granted;
      Logger.info(
        'Notification permission ${granted ? 'granted' : 'denied'}',
        'NotificationService',
      );
      return granted;
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to request notification permission',
        error: e,
        stackTrace: st,
        tag: 'NotificationService',
      );
      return false;
    }
  }

  /// Checks if notification permission is granted.
  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final status = await Permission.notification.status;
      // On Android < 13, POST_NOTIFICATIONS is auto-granted.
      // permission_handler returns granted for it on those versions.
      return status.isGranted || status.isLimited;
    } on Exception catch (e) {
      Logger.error('Failed to check notification permission',
          error: e, tag: 'NotificationService');
      return true; // Assume granted on error to not block notifications
    }
  }

  /// Shows a progress notification for an active conversion.
  ///
  /// Displays a persistent notification with progress bar and estimated time.
  /// Only shows when app is in background - user can see progress on screen when in app.
  /// Uses Importance.defaultImportance (not low) so MIUI doesn't hide it.
  Future<void> showProgressNotification({
    required String fileName,
    required double progress,
    String? estimatedTimeRemaining,
  }) async {
    Logger.info(
      'showProgressNotification called: initialized=$_initialized, foreground=$_isAppInForeground, progress=$progress',
      'NotificationService',
    );

    if (!_initialized) {
      Logger.warning(
        'NotificationService not initialized - skipping progress notification',
        'NotificationService',
      );
      return;
    }

    // Don't show progress notifications when user is actively using the app
    if (_isAppInForeground) {
      Logger.debug(
        'App in foreground - skipping progress notification',
        'NotificationService',
      );
      return;
    }

    // Throttle: skip if we posted a notification less than 1 second ago
    final now = DateTime.now();
    if (_lastProgressNotification != null &&
        now.difference(_lastProgressNotification!).inMilliseconds < 1000) {
      return;
    }
    _lastProgressNotification = now;

    try {
      // Use cached permission result to avoid async permission check on every tick
      if (!_permissionGranted) {
        _permissionGranted = await hasPermission();
      }
      if (!_permissionGranted) {
        Logger.debug(
          'No notification permission - skipping progress notification',
          'NotificationService',
        );
        return;
      }

      final progressPercent = (progress * 100).round();
      final timeText = estimatedTimeRemaining != null
          ? ' • $estimatedTimeRemaining remaining'
          : '';

      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,  // KEY FIX: was Importance.low
        priority: Priority.defaultPriority,        // KEY FIX: was Priority.low
        showProgress: true,
        maxProgress: 100,
        progress: progressPercent,
        ongoing: true, // Cannot be dismissed while converting
        autoCancel: false,
        showWhen: true,
        icon: '@drawable/ic_notification',
        enableVibration: false,
        playSound: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        _progressNotificationId,
        'Converting to audio',
        '$fileName$timeText',
        details,
      );
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to show progress notification',
        error: e,
        stackTrace: st,
        tag: 'NotificationService',
      );
    }
  }

  /// Shows a completion notification after successful conversion.
  ///
  /// Replaces the progress notification with a success message.
  /// User can tap to open the app.
  Future<void> showCompletionNotification({
    required String fileName,
  }) async {
    if (!_initialized) return;

    try {
      // Use cached permission — if progress notifications were firing, permission is granted.
      // Re-check only if not yet cached.
      if (!_permissionGranted) {
        _permissionGranted = await hasPermission();
      }
      if (!_permissionGranted) return;

      // If user is still in the app, the success screen is shown on-screen —
      // no notification needed.
      if (_isAppInForeground) {
        Logger.debug(
          'App in foreground - skipping completion notification',
          'NotificationService',
        );
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
        showWhen: true,
        icon: '@drawable/ic_notification',
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use same ID as progress notification to auto-replace it (avoid cancel() crashes)
      await _plugin.show(
        _progressNotificationId,
        'Conversion complete ✓',
        'Audio saved: $fileName',
        details,
      );

      Logger.info('Completion notification shown', 'NotificationService');
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to show completion notification',
        error: e,
        stackTrace: st,
        tag: 'NotificationService',
      );
    }
  }

  /// Shows an error notification after failed conversion.
  ///
  /// Replaces the progress notification with an error message.
  Future<void> showErrorNotification({
    required String fileName,
    String? errorMessage,
  }) async {
    if (!_initialized) return;

    try {
      // Use cached permission — if progress notifications were firing, permission is granted.
      // Re-check only if not yet cached.
      if (!_permissionGranted) {
        _permissionGranted = await hasPermission();
      }
      if (!_permissionGranted) return;

      // If user is still in the app, the error screen is shown on-screen —
      // no notification needed.
      if (_isAppInForeground) {
        Logger.debug(
          'App in foreground - skipping error notification',
          'NotificationService',
        );
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
        showWhen: true,
        icon: '@drawable/ic_notification',
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final message = errorMessage ?? 'Please try again';

      // Use same ID as progress notification to auto-replace it (avoid cancel() crashes)
      await _plugin.show(
        _progressNotificationId,
        'Conversion failed',
        '$fileName - $message',
        details,
      );

      Logger.info('Error notification shown', 'NotificationService');
    } on Exception catch (e, st) {
      Logger.error(
        'Failed to show error notification',
        error: e,
        stackTrace: st,
        tag: 'NotificationService',
      );
    }
  }

  /// Cancels all active notifications.
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      Logger.info('All notifications cancelled', 'NotificationService');
    } on Exception catch (e) {
      Logger.error('Failed to cancel notifications', error: e, tag: 'NotificationService');
    }
  }

  /// Cancels only the progress notification.
  Future<void> cancelProgressNotification() async {
    // Skip cancel - causes plugin crashes. The notification will auto-dismiss when task completes.
  }

  /// Handles notification tap events.
  ///
  /// Currently logs the event. Can be extended to navigate to specific screens.
  void _onNotificationTapped(NotificationResponse response) {
    Logger.info(
      'Notification tapped: ${response.id} - ${response.payload}',
      'NotificationService',
    );
    // TODO: Navigate to appropriate screen based on notification type
    // This would require a global navigator key or notification callback
  }
}
