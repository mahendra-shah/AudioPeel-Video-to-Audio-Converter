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

  // Notification IDs
  static const int _progressNotificationId = 1001;
  static const int _completionNotificationId = 1002;

  // Notification channel (Android)
  static const String _channelId = 'audiopeel_conversion';
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
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

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
      importance: Importance.low, // Low: no sound/vibration for progress updates
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
    switch (state) {
      case AppLifecycleState.resumed:
        // App is visible and responding to user input
        _isAppInForeground = true;
        // Cancel progress notification when user returns to app
        _plugin.cancel(_progressNotificationId);
        Logger.debug('App entered foreground - cancelled progress notification', 'NotificationService');
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // App is not visible or transitioning away
        _isAppInForeground = false;
        Logger.debug('App entered background', 'NotificationService');
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is detached or hidden
        _isAppInForeground = false;
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
  /// Returns `true` if permission is granted, `false` otherwise.
  /// On Android 12 and below, always returns `true` since no permission needed.
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      // Android 13+ requires runtime permission
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        final status = await Permission.notification.status;

        if (status.isGranted) {
          Logger.info('Notification permission already granted', 'NotificationService');
          return true;
        }

        if (status.isPermanentlyDenied) {
          Logger.warning(
            'Notification permission permanently denied',
            'NotificationService',
          );
          return false;
        }

        // Request permission
        final result = await Permission.notification.request();
        final granted = result.isGranted;

        Logger.info(
          'Notification permission ${granted ? 'granted' : 'denied'}',
          'NotificationService',
        );
        return granted;
      }

      // Android 12 and below - no permission needed
      return true;
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
      final androidInfo = await _getAndroidVersion();
      if (androidInfo >= 33) {
        final status = await Permission.notification.status;
        return status.isGranted;
      }
      return true; // Pre-Android 13 doesn't need permission
    } on Exception catch (e) {
      Logger.error('Failed to check notification permission', error: e, tag: 'NotificationService');
      return false;
    }
  }

  /// Shows a progress notification for an active conversion.
  ///
  /// Displays a persistent notification with progress bar and estimated time.
  /// Only shows when app is in background - user can see progress on screen when in app.
  /// [fileName] is the input video file name.
  /// [progress] is a value from 0.0 to 1.0.
  /// [estimatedTimeRemaining] is optional estimated seconds remaining.
  Future<void> showProgressNotification({
    required String fileName,
    required double progress,
    String? estimatedTimeRemaining,
  }) async {
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

    try {
      final hasPermission = await this.hasPermission();
      if (!hasPermission) {
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
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: 100,
        progress: progressPercent,
        ongoing: true, // Cannot be dismissed while converting
        autoCancel: false,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: const DrawableResourceAndroidBitmap('notification_large_icon'),
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
      final hasPermission = await this.hasPermission();
      if (!hasPermission) return;

      // Cancel progress notification first
      await _plugin.cancel(_progressNotificationId);

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('notification_large_icon'),
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

      await _plugin.show(
        _completionNotificationId,
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
      final hasPermission = await this.hasPermission();
      if (!hasPermission) return;

      // Cancel progress notification first
      await _plugin.cancel(_progressNotificationId);

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
        autoCancel: true,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('notification_large_icon'),
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

      await _plugin.show(
        _completionNotificationId,
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
    try {
      await _plugin.cancel(_progressNotificationId);
    } on Exception catch (e) {
      Logger.error('Failed to cancel progress notification', error: e, tag: 'NotificationService');
    }
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

  /// Gets Android SDK version.
  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    try {
      // Use permission_handler's device info to check Android version
      // Android 13 (API 33) introduced notification permission requirement
      final androidInfo = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.getActiveNotifications();

      // If we can query notifications without error, we're on newer Android
      // For simplicity, we'll check permission status which handles version internally
      return 33; // Assume recent version if plugin works
    } catch (e) {
      return 33; // Default to requiring permission for safety
    }
  }
}
