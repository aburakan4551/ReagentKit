import 'package:flutter/foundation.dart';
import 'package:reagentkit/core/globals.dart';

/// Guard to prevent execution of premium/payment logic during Review Mode.
class ReviewRuntimeGuard {
  /// Centralized runtime assertions to verify Review Mode status.
  static void runGuard() {
    assert(() {
      if (isPremiumReviewMode) {
        debugPrint('⚠️ [Review Guard] Premium/payment runtime assertions active.');
      }
      return true;
    }());
  }

  /// Verifies whether a billing/purchase operation should be blocked.
  /// 
  /// Returns `true` if blocked (Review Mode active), guiding the caller
  /// to return a fallback value rather than throwing an exception.
  static bool checkAndBlock(String actionName) {
    if (isPremiumReviewMode) {
      debugPrint('🛡️ [Review Guard] Blocked execution of billing flow: "$actionName"');
      return true;
    }
    return false;
  }
}
