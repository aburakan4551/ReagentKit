enum AppEnvironment {
  review,
  production,
  development
}

/// The current build environment configuration.
/// 
/// Set to [AppEnvironment.review] for Apple App Store first submission.
/// Set to [AppEnvironment.production] before production monetized releases.
const AppEnvironment currentEnvironment = AppEnvironment.review;

/// Centralized flag to indicate whether the app is in Safe Review Mode.
/// 
/// Automatically enabled in [AppEnvironment.review], otherwise disabled.
bool get isPremiumReviewMode => currentEnvironment == AppEnvironment.review;
