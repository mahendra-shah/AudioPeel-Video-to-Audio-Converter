import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Builds light and dark [ThemeData] from the Peel tokens.
abstract final class PeelTheme {
  static ThemeData get light => _build(PeelColors.light, Brightness.light);
  static ThemeData get dark => _build(PeelColors.dark, Brightness.dark);

  static ThemeData _build(PeelColors c, Brightness b) {
    final isDark = b == Brightness.dark;
    final scheme = ColorScheme(
      brightness: b,
      primary: c.peel,
      onPrimary: c.onPeel,
      primaryContainer: c.peel.withValues(alpha: 0.16),
      onPrimaryContainer: c.peel,
      secondary: c.groove,
      onSecondary: isDark ? const Color(0xFF04201C) : Colors.white,
      secondaryContainer: c.groove.withValues(alpha: 0.16),
      onSecondaryContainer: c.groove,
      surface: c.canvas,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceContainerLowest: c.canvas,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceHi,
      surfaceContainerHighest: c.surfaceHi,
      error: c.danger,
      onError: Colors.white,
      outline: c.line,
      outlineVariant: c.line,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: c.ink,
      onInverseSurface: c.canvas,
    );

    final text = _text(c);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: Fonts.sans,
      textTheme: text,
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.canvas,
      splashFactory: InkSparkle.splashFactory,
      extensions: [c],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.scaled,
            fillColor: Colors.transparent,
          ),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleMedium,
        iconTheme: IconThemeData(color: c.ink),
        systemOverlayStyle: (isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark)
            .copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: c.canvas,
            ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.canvas,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.peel.withValues(alpha: 0.16),
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium?.copyWith(
            color: s.contains(WidgetState.selected) ? c.ink : c.inkMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? c.peel : c.inkMuted,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.canvas),
        actionTextColor: c.peel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.chip),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: c.inkFaint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.hero)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.hero),
        ),
        titleTextStyle: text.titleMedium,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.inkMuted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceHi,
        hintStyle: text.bodyMedium?.copyWith(color: c.inkFaint),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.chip),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.chip),
          borderSide: BorderSide(color: c.peel, width: 1.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onPeel : c.inkMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.peel : c.surfaceHi,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.peel,
        inactiveTrackColor: c.surfaceHi,
        thumbColor: c.peel,
        overlayColor: c.peel.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.peel),
      iconTheme: IconThemeData(color: c.ink),
    );
  }

  static TextTheme _text(PeelColors c) {
    TextStyle s(double size, FontWeight w, {double? ls, double h = 1.3}) =>
        TextStyle(
          fontFamily: Fonts.sans,
          fontSize: size,
          fontWeight: w,
          letterSpacing: ls,
          height: h,
          color: c.ink,
        );
    return TextTheme(
      displaySmall: s(34, FontWeight.w800, ls: -0.8, h: 1.1),
      headlineMedium: s(28, FontWeight.w800, ls: -0.6, h: 1.15),
      headlineSmall: s(24, FontWeight.w700, ls: -0.4, h: 1.2),
      titleLarge: s(20, FontWeight.w700, ls: -0.2),
      titleMedium: s(18, FontWeight.w700, ls: -0.1),
      titleSmall: s(15, FontWeight.w700),
      bodyLarge: s(16, FontWeight.w500, h: 1.45),
      bodyMedium: s(15, FontWeight.w500, h: 1.45),
      bodySmall: s(13, FontWeight.w500, h: 1.4).copyWith(color: c.inkMuted),
      labelLarge: s(15, FontWeight.w700, ls: 0.1),
      labelMedium: s(13, FontWeight.w600),
      labelSmall: s(11, FontWeight.w700, ls: 0.8),
    );
  }
}
