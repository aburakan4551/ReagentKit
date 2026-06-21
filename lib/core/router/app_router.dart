import 'package:flutter/material.dart';
import 'package:reagentkit/core/globals.dart';
import 'package:reagentkit/core/navigation/auth_wrapper.dart';
import 'package:reagentkit/features/premium/presentation/screens/paywall_screen.dart';
import 'package:reagentkit/core/utils/logger.dart';

/// Navigation router configuration and path manager.
class AppRouter {
  static const String home = '/';
  static const String subscriptionPage = 'subscription_page';
  static const String premiumPage = 'premium_page';
  static const String paywallPage = 'paywall_page';

  /// Generates dynamic Material routes with safety guards active in Review Mode.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    if (isPremiumReviewMode) {
      if (settings.name == subscriptionPage ||
          settings.name == premiumPage ||
          settings.name == paywallPage) {
        Logger.info('🛡️ [Router Guard] Intercepted navigation attempt to: "${settings.name}". Redirecting to Home.');
        return MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
          settings: const RouteSettings(name: home),
        );
      }
    }

    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
          settings: settings,
        );
      case paywallPage:
      case premiumPage:
      case subscriptionPage:
        return MaterialPageRoute(
          builder: (context) => const PaywallScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
          settings: settings,
        );
    }
  }
}
