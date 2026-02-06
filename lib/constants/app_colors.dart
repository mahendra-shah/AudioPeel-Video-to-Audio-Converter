import 'package:flutter/material.dart';

/// Centralised color definitions for light and dark themes.
///
/// All hex values come from the approved design system. Never use
/// hard-coded color literals elsewhere — reference these constants.
abstract final class AppColors {
  // ─── Brand ──────────────────────────────────────────────────────────

  /// Primary brand blue used for CTAs and active elements.
  static const Color primary = Color(0xFF2563EB);

  /// Lighter primary tint for hover / pressed states.
  static const Color primaryLight = Color(0xFF3B82F6);

  /// Darker primary shade.
  static const Color primaryDark = Color(0xFF1D4ED8);

  // ─── Surface ────────────────────────────────────────────────────────

  /// Root background in light mode.
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Root background in dark mode.
  static const Color surfaceDark = Color(0xFF0F172A);

  /// Card / elevated surface in light mode.
  static const Color cardLight = Color(0xFFF8FAFC);

  /// Card / elevated surface in dark mode.
  static const Color cardDark = Color(0xFF1E293B);

  // ─── Text ───────────────────────────────────────────────────────────

  /// Primary text in light mode.
  static const Color textPrimaryLight = Color(0xFF0F172A);

  /// Primary text in dark mode.
  static const Color textPrimaryDark = Color(0xFFF8FAFC);

  /// Secondary / subtitle text in light mode.
  static const Color textSecondaryLight = Color(0xFF64748B);

  /// Secondary / subtitle text in dark mode.
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // ─── Semantic ───────────────────────────────────────────────────────

  /// Success indicator (completed conversions).
  static const Color success = Color(0xFF10B981);

  /// Error / failure indicator.
  static const Color error = Color(0xFFEF4444);

  /// Warning / promotional accent (Remove Ads CTA).
  static const Color warning = Color(0xFFF59E0B);

  // ─── Divider / Border ───────────────────────────────────────────────

  /// Subtle divider in light mode.
  static const Color dividerLight = Color(0xFFE2E8F0);

  /// Subtle divider in dark mode.
  static const Color dividerDark = Color(0xFF334155);

  // ─── Overlay ────────────────────────────────────────────────────────

  /// Scrim overlay for modals / bottom-sheets.
  static const Color scrim = Color(0x80000000);
}
