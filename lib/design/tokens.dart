import 'package:flutter/material.dart';

/// The "Peel" palette — tangerine + groove teal on warm ink / cream.
///
/// Exposed as a [ThemeExtension] so every widget reads colors through
/// `context.peel` and light/dark switch with a smooth lerp.
@immutable
class PeelColors extends ThemeExtension<PeelColors> {
  const PeelColors({
    required this.canvas,
    required this.surface,
    required this.surfaceHi,
    required this.line,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.peel,
    required this.peelDeep,
    required this.onPeel,
    required this.groove,
    required this.danger,
    required this.warning,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceHi;
  final Color line;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint;
  final Color peel;
  final Color peelDeep;
  final Color onPeel;
  final Color groove;
  final Color danger;
  final Color warning;

  static const dark = PeelColors(
    canvas: Color(0xFF0F0D0B),
    surface: Color(0xFF1A1714),
    surfaceHi: Color(0xFF252019),
    line: Color(0x14FFFFFF),
    ink: Color(0xFFFFF7EE),
    inkMuted: Color(0x99FFF7EE),
    inkFaint: Color(0x52FFF7EE),
    peel: Color(0xFFFF8A3D),
    peelDeep: Color(0xFFFF5E3A),
    onPeel: Color(0xFF1A0D05),
    groove: Color(0xFF3CC8B4),
    danger: Color(0xFFFF5C5C),
    warning: Color(0xFFFFC857),
  );

  static const light = PeelColors(
    canvas: Color(0xFFFBF6EF),
    surface: Color(0xFFFFFFFF),
    surfaceHi: Color(0xFFF3ECE2),
    line: Color(0x141A1714),
    ink: Color(0xFF1A1512),
    inkMuted: Color(0x941A1512),
    inkFaint: Color(0x521A1512),
    peel: Color(0xFFF2711C),
    peelDeep: Color(0xFFE0521A),
    onPeel: Color(0xFFFFFFFF),
    groove: Color(0xFF139C8A),
    danger: Color(0xFFD93A3A),
    warning: Color(0xFFB7791F),
  );

  /// The signature CTA / progress gradient.
  LinearGradient get peelGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [peel, peelDeep],
  );

  @override
  PeelColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceHi,
    Color? line,
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    Color? peel,
    Color? peelDeep,
    Color? onPeel,
    Color? groove,
    Color? danger,
    Color? warning,
  }) {
    return PeelColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceHi: surfaceHi ?? this.surfaceHi,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      peel: peel ?? this.peel,
      peelDeep: peelDeep ?? this.peelDeep,
      onPeel: onPeel ?? this.onPeel,
      groove: groove ?? this.groove,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
    );
  }

  @override
  PeelColors lerp(ThemeExtension<PeelColors>? other, double t) {
    if (other is! PeelColors) return this;
    return PeelColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHi: Color.lerp(surfaceHi, other.surfaceHi, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      peel: Color.lerp(peel, other.peel, t)!,
      peelDeep: Color.lerp(peelDeep, other.peelDeep, t)!,
      onPeel: Color.lerp(onPeel, other.onPeel, t)!,
      groove: Color.lerp(groove, other.groove, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

/// Spacing, radii and type scale.
abstract final class Space {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal page gutter.
  static const double gutter = 20;
}

abstract final class Radii {
  static const double chip = 12;
  static const double card = 20;
  static const double hero = 28;
  static const double pill = 999;
}

abstract final class Fonts {
  static const String sans = 'Jakarta';
  static const String mono = 'JetBrainsMono';
}

extension PeelContext on BuildContext {
  /// Brand colors for the current theme.
  PeelColors get peel => Theme.of(this).extension<PeelColors>()!;

  TextTheme get text => Theme.of(this).textTheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Monospaced numeric style for timecodes, sizes and percentages.
TextStyle monoStyle(BuildContext context, {double size = 13, Color? color}) {
  return TextStyle(
    fontFamily: Fonts.mono,
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: color ?? context.peel.inkMuted,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
