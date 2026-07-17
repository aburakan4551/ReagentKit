import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:reagentkit/core/globals.dart';
import 'package:reagentkit/core/utils/logger.dart';

/// Isolation wrapper for RevenueCat subscription SDK.
class RevenueCatService {
  /// Safely configures the RevenueCat SDK, bypassing it entirely in review mode.
  static Future<void> configure(String apiKey, String appUserID) async {
    if (isPremiumReviewMode) {
      Logger.info('🛡️ [RevenueCat Isolation] SDK configuration bypassed.');
      return;
    }
    try {
      final configuration = PurchasesConfiguration(apiKey)..appUserID = appUserID;
      await Purchases.configure(configuration);
      Logger.info('✅ [RevenueCat] SDK configured successfully.');
    } catch (e) {
      Logger.error('❌ [RevenueCat] Configuration error: $e');
    }
  }

  /// Fetches available packages, returning an empty list in review mode.
  static Future<List<Package>> getOfferings() async {
    if (isPremiumReviewMode) {
      Logger.info('🛡️ [RevenueCat Isolation] Offerings query bypassed. Returning empty list.');
      return const [];
    }
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        return offerings.current!.availablePackages;
      }
    } catch (e) {
      Logger.error('❌ [RevenueCat] Offerings fetch failed: $e');
    }
    return const [];
  }
}
