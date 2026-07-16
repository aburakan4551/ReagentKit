import 'package:reagentkit/core/globals.dart';

/// Validation utility to safeguard production monetization builds.
class BuildReleaseCheck {
  /// Asserts that App Store Review Mode is disabled in production releases.
  ///
  /// Throws an [Exception] if review mode is accidentally enabled in a production build.
  static void validate() {
    if (currentEnvironment == AppEnvironment.production &&
        isPremiumReviewMode) {
      throw Exception(
          'CRITICAL SAFETY EXCEPTION: App Store Review Mode (isPremiumReviewMode = true) '
          'must never be enabled in a production monetized release.');
    }
  }
}
