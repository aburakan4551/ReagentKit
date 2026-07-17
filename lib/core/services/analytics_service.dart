import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:reagentkit/core/globals.dart';
import 'package:reagentkit/core/utils/logger.dart';

/// Telemetry wrapper that filters marketing events during review.
class AnalyticsService {
  /// Logs a Firebase Analytics event, filtering out sensitive billing events.
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (isPremiumReviewMode) {
      // Discard monetization and routing events
      if (name == 'purchase_attempt' ||
          name == 'subscription_restore' ||
          name == 'paywall_opened' ||
          name == 'premium_purchase_success' ||
          name == 'free_scan_consumed') {
        Logger.info('🛡️ [Analytics Isolation] Suppressed logging premium event: "$name"');
        return;
      }
    }

    try {
      final finalParams = <String, Object>{...?parameters};
      if (isPremiumReviewMode) {
        finalParams['review_mode_session'] = 'true';
      }
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: finalParams,
      );
    } catch (e) {
      Logger.error('Analytics log event failed: $e');
    }
  }

  /// Sets user properties, automatically tagging review sessions.
  static Future<void> setUserProperties() async {
    try {
      if (isPremiumReviewMode) {
        await FirebaseAnalytics.instance.setUserProperty(
          name: 'reviewer_session',
          value: 'true',
        );
      }
    } catch (e) {
      Logger.error('Analytics setUserProperties failed: $e');
    }
  }
}
