import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The motion system. Every animated value in the app comes from here so the
/// whole product moves with one rhythm.
abstract final class Motion {
  // ─── Durations ─────────────────────────────────────────────────────
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration short = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 380);
  static const Duration long = Duration(milliseconds: 560);
  static const Duration hero = Duration(milliseconds: 760);

  /// Delay between staggered list items.
  static const Duration stagger = Duration(milliseconds: 40);

  // ─── Curves ────────────────────────────────────────────────────────
  static const Curve standard = Cubic(0.2, 0, 0, 1);
  static const Curve emphasized = Cubic(0.2, 0, 0, 1);
  static const Curve emphasizedDecel = Cubic(0.05, 0.7, 0.1, 1);
  static const Curve emphasizedAccel = Cubic(0.3, 0, 0.8, 0.15);
  static const Curve overshoot = Cubic(0.34, 1.56, 0.64, 1);

  /// Spring used by every pressable surface.
  static const SpringDescription pressSpring = SpringDescription(
    mass: 1,
    stiffness: 520,
    damping: 28,
  );

  /// Whether the user asked the OS to remove animations.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Returns [d], or zero when reduced motion is on.
  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;

  /// Delay for the item at [index] in a staggered entrance (capped at 8).
  static Duration staggerFor(int index) => stagger * index.clamp(0, 8);

  // ─── Page routes ───────────────────────────────────────────────────

  /// Forward navigation along the Z axis (scale + fade).
  static Route<T> sharedAxis<T>(
    Widget page, {
    SharedAxisTransitionType type = SharedAxisTransitionType.scaled,
  }) {
    return PageRouteBuilder<T>(
      transitionDuration: long,
      reverseTransitionDuration: medium,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (context, animation, secondary, child) {
        if (reduced(context)) return child;
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondary,
          transitionType: type,
          fillColor: Colors.transparent,
          child: child,
        );
      },
    );
  }

  /// Fade-through for peer destinations.
  static Route<T> fadeThrough<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: long,
      reverseTransitionDuration: medium,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (context, animation, secondary, child) {
        if (reduced(context)) return child;
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondary,
          fillColor: Colors.transparent,
          child: child,
        );
      },
    );
  }
}

/// Haptic vocabulary — one meaning per call.
abstract final class Haptics {
  static void tap() => HapticFeedback.lightImpact();
  static void select() => HapticFeedback.selectionClick();
  static void commit() => HapticFeedback.mediumImpact();
  static void success() => HapticFeedback.heavyImpact();
  static void warn() => HapticFeedback.vibrate();
}
