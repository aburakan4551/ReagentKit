import 'package:flutter/foundation.dart';
import 'package:reagentkit/core/globals.dart';

/// Service to handle StoreKit/IAP purchase attempts and fallbacks.
class IapService {
  /// Simulates buying a package, returning true safely without calling StoreKit.
  static Future<bool> buyPremium(String packageIdentifier) async {
    if (isPremiumReviewMode) {
      debugPrint(
          '[Review Mode] Mock premium purchase bypassed for package: $packageIdentifier.');
      return true;
    }
    // Production billing logic goes here
    return false;
  }

  /// Simulates restoring purchases, returning true safely.
  static Future<bool> restorePurchases() async {
    if (isPremiumReviewMode) {
      debugPrint('[Review Mode] Mock restore purchases bypassed.');
      return true;
    }
    // Production restore logic goes here
    return false;
  }
}
