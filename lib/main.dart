import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/ad_provider.dart';
import 'providers/conversion_provider.dart';
import 'providers/history_provider.dart';
import 'providers/settings_provider.dart';
import 'services/iap_service.dart';
import 'services/storage_service.dart';
import 'utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for consistent layout.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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

  // Initialise IAP service — non-fatal if it fails.
  final iapService = IapService();
  try {
    await iapService.initialise();
  } on Exception catch (e, st) {
    Logger.error('IAP init failed', error: e, stackTrace: st, tag: 'Main');
  }

  // Sync IAP state → settings if already purchased.
  if (iapService.isPurchased && !settingsProvider.adsRemoved) {
    await settingsProvider.markAdsRemoved();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => ConversionProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider.value(value: iapService),
        ChangeNotifierProvider(
          create: (_) {
            final adProvider = AdProvider()
              ..syncAdsRemoved(settingsProvider.adsRemoved);
            adProvider.loadInterstitial();
            return adProvider;
          },
        ),
      ],
      child: const Mp3ExtractApp(),
    ),
  );
}
