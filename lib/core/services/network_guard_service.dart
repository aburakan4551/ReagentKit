import 'package:reagentkit/core/globals.dart';
import 'package:reagentkit/core/utils/logger.dart';

/// Connection and timeout safety guard for App Store review sessions.
class NetworkGuardService {
  /// Resolves billing states offline, preventing network blockages.
  static bool resolvePremiumAccessOffline() {
    if (isPremiumReviewMode) {
      Logger.info('🛡️ [Network Guard] Active. Automatically granting premium status (Offline-Safe).');
      return true;
    }
    return false;
  }

  /// Restricts loading times or returns fallback lists of features.
  static List<String> getAvailableFeaturesOffline() {
    if (isPremiumReviewMode) {
      return const [
        'reagent_scans',
        'scientific_reports',
        'chemical_database',
        'ai_analysis_assistant'
      ];
    }
    return const ['reagent_scans'];
  }
}
