import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/logger.dart';

/// Google UMP consent (GDPR / UK / Switzerland) — required before serving
/// ads in those regions. Elsewhere it resolves immediately.
abstract final class ConsentService {
  static bool _privacyOptionsRequired = false;

  /// Whether Settings must show a "Privacy options" entry.
  static bool get privacyOptionsRequired => _privacyOptionsRequired;

  /// Refreshes consent info, shows the form if required, and returns whether
  /// ads may be requested.
  static Future<bool> gather() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) {
            Logger.warning('Consent form: ${error.message}', 'Consent');
          }
          if (!done.isCompleted) done.complete();
        });
      },
      (error) {
        Logger.warning('Consent update failed: ${error.message}', 'Consent');
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future.timeout(const Duration(seconds: 12), onTimeout: () {});
    try {
      _privacyOptionsRequired =
          await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      return await ConsentInformation.instance.canRequestAds();
    } on Exception {
      return false;
    }
  }

  static Future<void> showPrivacyOptions() async {
    await ConsentForm.showPrivacyOptionsForm((error) {
      if (error != null) {
        Logger.warning('Privacy options: ${error.message}', 'Consent');
      }
    });
  }
}
