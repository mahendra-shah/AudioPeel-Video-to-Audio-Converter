import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'constants/app_strings.dart';
import 'constants/app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';

/// Root widget that configures Material 3 theming and routing.
class AudioPeelApp extends StatelessWidget {
  const AudioPeelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const SplashScreen(),
        );
      },
    );
  }
}
