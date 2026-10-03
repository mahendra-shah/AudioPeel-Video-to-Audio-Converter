import 'package:flutter/material.dart';

import '../design/theme.dart';

/// Thin alias so the rest of the app refers to [AppTheme] rather than
/// [PeelTheme], keeping the public API stable if the implementation changes.
///
/// app.dart imports:
/// ```dart
/// import 'constants/app_theme.dart';
/// theme: AppTheme.light,
/// darkTheme: AppTheme.dark,
/// ```
abstract final class AppTheme {
  /// Full Material 3 light theme built from [PeelColors.light].
  static ThemeData get light => PeelTheme.light;

  /// Full Material 3 dark theme built from [PeelColors.dark].
  static ThemeData get dark => PeelTheme.dark;
}

