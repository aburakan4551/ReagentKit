import 'package:flutter/material.dart';
import 'package:reagentkit/core/globals.dart';
import 'package:reagentkit/core/router/app_router.dart';
import 'package:reagentkit/core/utils/logger.dart';

/// Interceptor for incoming deep links and external URLs.
class DeepLinkHandler {
  /// Handles deep links, blocking monetization routes during review.
  static void handleLink(BuildContext context, Uri deepLink) {
    final path = deepLink.path;
    if (isPremiumReviewMode) {
      if (path.contains('paywall') || 
          path.contains('subscription') || 
          path.contains('premium') || 
          path.contains('promo')) {
        Logger.info('🛡️ [Deep Link Shield] Blocked promotional path: "$path". Redirecting to home.');
        Navigator.of(context).pushReplacementNamed(AppRouter.home);
        return;
      }
    }
    // Normal deep link routing goes here
  }
}
