import 'package:flutter/material.dart';
import 'package:reagentkit/core/globals.dart';
import 'package:reagentkit/core/router/app_router.dart';
import 'package:reagentkit/core/utils/logger.dart';

/// Service to handle programmatic navigations and navigation state.
class NavigationService {
  final GlobalKey<NavigatorState> _navigatorKey;

  NavigationService(this._navigatorKey);

  /// Navigates to a named route, blocking payment screens in review mode.
  Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    if (isPremiumReviewMode) {
      if (routeName == AppRouter.subscriptionPage ||
          routeName == AppRouter.premiumPage ||
          routeName == AppRouter.paywallPage) {
        Logger.info(
            '🛡️ [Navigation Guard] Programmatic push blocked for: "$routeName". Redirecting to Home.');
        return _navigatorKey.currentState?.pushReplacementNamed(AppRouter.home);
      }
    }
    return _navigatorKey.currentState
        ?.pushNamed(routeName, arguments: arguments);
  }

  /// Pops the current route from the navigation stack.
  void goBack() {
    return _navigatorKey.currentState?.pop();
  }
}
