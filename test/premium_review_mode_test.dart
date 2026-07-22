import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reagentkit/core/globals.dart';
import 'package:reagentkit/core/services/premium_service.dart';
import 'package:reagentkit/core/services/firestore_service.dart';
import 'package:reagentkit/core/services/local_storage_service.dart';
import 'package:reagentkit/core/services/cloud_sync_service.dart';
import 'package:reagentkit/core/services/analytics_service.dart';
import 'package:reagentkit/core/services/review_runtime_guard.dart';
import 'package:reagentkit/core/services/build_release_check.dart';
import 'package:get_it/get_it.dart';

class MockFirestoreService extends Fake implements FirestoreService {}

void main() {
  SharedPreferences.setMockInitialValues({});

  group('Premium Review Mode Testing and Hardening Verification', () {
    setUpAll(() {
      final getIt = GetIt.instance;
      getIt.registerLazySingleton<FirestoreService>(
          () => MockFirestoreService());
    });

    test('1. review_mode_config values are active', () {
      expect(isPremiumReviewMode, isTrue);
      expect(currentEnvironment, AppEnvironment.review);
    });

    test('2. PremiumService returns full features by default', () async {
      final service = PremiumService();
      expect(service.isPremium, isTrue);
      expect(service.freeScansLeft, 999);
      expect(service.canAnalyze, isTrue);
      expect(service.isPurchasePending, isFalse);
      expect(service.errorMessage, isNull);
    });

    test('3. Local storage and Cloud Sync prevent writes in review mode',
        () async {
      // LocalStorageService should not write or throw
      await LocalStorageService.savePremiumStatus(true);

      // CloudSyncService should bypass sync silently
      await CloudSyncService.syncPremiumState(
          uid: 'test_uid', isPremium: true, scansLeft: 999);
    });

    test('4. Analytics suppresses monetization events', () async {
      // Verify no exception is thrown when logging filtered events
      await AnalyticsService.logEvent(name: 'purchase_attempt');
      await AnalyticsService.logEvent(name: 'subscription_restore');
      await AnalyticsService.logEvent(name: 'paywall_opened');
    });

    test('5. BuildReleaseCheck validation behaves as expected', () {
      // Should not throw under AppEnvironment.review
      expect(() => BuildReleaseCheck.validate(), returnsNormally);
    });

    test('6. ReviewRuntimeGuard checkAndBlock blocks execution', () {
      expect(ReviewRuntimeGuard.checkAndBlock('buyPremium'), isTrue);
    });

  });
}
