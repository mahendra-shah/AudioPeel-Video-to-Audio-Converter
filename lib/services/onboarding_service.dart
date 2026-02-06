import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has completed the onboarding product tour.
class OnboardingService {
  static const _prefOnboardingComplete = 'onboarding_complete';

  /// Returns `true` if the user has already seen the product tour.
  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefOnboardingComplete) ?? false;
  }

  /// Marks the onboarding tour as complete so it won't show again.
  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefOnboardingComplete, true);
  }

  /// Resets the onboarding state (for testing purposes).
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefOnboardingComplete);
  }
}
