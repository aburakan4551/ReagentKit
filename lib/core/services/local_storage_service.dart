import 'package:shared_preferences/shared_preferences.dart';
import 'package:reagentkit/core/globals.dart';
import 'package:reagentkit/core/utils/logger.dart';

/// Storage manager that blocks persisting review-mode configurations.
class LocalStorageService {
  static const String _premiumUserKey = 'is_premium_user';

  /// Saves the premium status only when not running in review mode.
  static Future<void> savePremiumStatus(bool isPremium) async {
    if (isPremiumReviewMode) {
      Logger.info(
          '🛡️ [Storage Security] Blocked writing temporary premium status to local preferences.');
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumUserKey, isPremium);
    } catch (e) {
      Logger.error('Failed to write premium status: $e');
    }
  }
}
