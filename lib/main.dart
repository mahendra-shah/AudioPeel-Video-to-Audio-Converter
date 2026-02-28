import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/env.dart';
import 'providers/ad_provider.dart';
import 'providers/conversion_provider.dart';
import 'providers/history_provider.dart';
import 'providers/settings_provider.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for consistent layout.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Safety check: Warn if using test ads in release mode
  if (kReleaseMode && !Env.isProduction) {
    Logger.error(
      '⚠️ CRITICAL: RELEASE BUILD with TEST AD IDs! '
      'Build with: flutter build appbundle --release --dart-define=PRODUCTION=true '
      'Submitting to Play Store with test ad IDs will result in REJECTION or account SUSPENSION!',
      tag: 'Main',
    );
    // In a real production scenario, you might want to show an in-app banner or prevent app launch
  }

  // Initialise the Mobile Ads SDK — non-fatal if it fails.
  try {
    await MobileAds.instance.initialize();
  } on Exception catch (e, st) {
    Logger.error(
      'MobileAds init failed',
      error: e,
      stackTrace: st,
      tag: 'Main',
    );
  }

  // Pre-load persisted settings before first frame.
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  // Initialise the storage service with any persisted custom output path.
  await StorageService().init();

  // Initialise notification service for conversion progress notifications.
  try {
    await NotificationService.instance.initialize();
  } on Exception catch (e, st) {
    Logger.error(
      'NotificationService init failed',
      error: e,
      stackTrace: st,
      tag: 'Main',
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => ConversionProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final adProvider = AdProvider();
            adProvider.loadInterstitial();
            return adProvider;
          },
        ),
      ],
      child: const AudioPeelApp(),
    ),
  );
}
