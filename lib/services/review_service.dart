import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

/// Asks happy users for a rating at the right moment.
///
/// Rules: only after 2+ successful conversions, only from a positive action
/// (play / share on the result), at most once every 60 days.
abstract final class ReviewService {
  static const _prefLastAsk = 'review_last_ask_ms';
  static const _prefSuccess = 'total_conversions';
  static const _cooldown = Duration(days: 60);

  static Future<void> maybeAsk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final successes = prefs.getInt(_prefSuccess) ?? 0;
      if (successes < 2) return;
      final last = prefs.getInt(_prefLastAsk) ?? 0;
      final since = DateTime.now().millisecondsSinceEpoch - last;
      if (since < _cooldown.inMilliseconds) return;
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      await prefs.setInt(_prefLastAsk, DateTime.now().millisecondsSinceEpoch);
      await review.requestReview();
    } on Exception catch (e) {
      Logger.warning('review prompt failed: $e', 'ReviewService');
    }
  }

  /// Opens the Play Store listing (Settings → Rate).
  static Future<void> openStore() =>
      InAppReview.instance.openStoreListing();
}
