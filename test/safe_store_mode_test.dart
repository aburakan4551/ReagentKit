import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reagentkit/core/services/safe_store_sanitizer.dart';
import 'package:reagentkit/core/services/safe_store_backup_manager.dart';
import 'package:reagentkit/features/reagent_testing/data/services/remote_config_service.dart';

class FakeFirebaseRemoteConfig extends Fake implements FirebaseRemoteConfig {
  final Map<String, dynamic> _mockValues = {};

  void setMockValue(String key, dynamic value) {
    _mockValues[key] = value;
  }

  @override
  Future<void> setConfigSettings(RemoteConfigSettings settings) async {}

  @override
  Future<void> setDefaults(Map<String, dynamic> defaults) async {
    defaults.forEach((key, value) {
      _mockValues.putIfAbsent(key, () => value);
    });
  }

  @override
  Future<bool> fetchAndActivate() async => true;

  @override
  Future<bool> activate() async => true;

  @override
  String getString(String key) => _mockValues[key]?.toString() ?? '';

  @override
  bool getBool(String key) {
    final val = _mockValues[key];
    if (val is bool) return val;
    if (val == 'true') return true;
    return false;
  }

  @override
  Stream<RemoteConfigUpdate> get onConfigUpdated => const Stream.empty();
}

void main() {
  // Ensure shared_preferences has a mocked storage before running tests
  SharedPreferences.setMockInitialValues({});

  group('SafeStoreSanitizer Tests', () {
    setUp(() {
      SafeStoreSanitizer.safeStoreMode = false;
    });

    test('Does not sanitize when safeStoreMode is false', () {
      expect(SafeStoreSanitizer.sanitize('cocaine'), equals('cocaine'));
      expect(SafeStoreSanitizer.sanitize('كوكايين'), equals('كوكايين'));
    });

    test('Sanitizes English terms when safeStoreMode is true', () {
      SafeStoreSanitizer.safeStoreMode = true;
      expect(SafeStoreSanitizer.sanitize('cocaine'),
          equals('controlled compounds'));
      expect(
          SafeStoreSanitizer.sanitize('heroin'), equals('alkaloid compounds'));
      expect(
          SafeStoreSanitizer.sanitize('Lsd'),
          equals(
              'Chemical reagents')); // Casing preserved (first letter uppercase)
      expect(SafeStoreSanitizer.sanitize('LSD'),
          equals('CHEMICAL REAGENTS')); // Casing preserved (all uppercase)
      expect(SafeStoreSanitizer.sanitize('Ecstasy'),
          equals('Forensic chemistry compounds'));
      expect(SafeStoreSanitizer.sanitize('narcotics'),
          equals('educational chemistry analysis'));
      expect(SafeStoreSanitizer.sanitize('drugs of abuse'),
          equals('educational chemistry references'));
      expect(SafeStoreSanitizer.sanitize('cannabis'),
          equals('botanical compounds'));
      expect(
          SafeStoreSanitizer.sanitize('khat'), equals('botanical specimens'));
      expect(
          SafeStoreSanitizer.sanitize('This is cocaine and heroin testing'),
          equals(
              'This is controlled compounds and alkaloid compounds testing'));
    });

    test('Sanitizes Arabic terms when safeStoreMode is true', () {
      SafeStoreSanitizer.safeStoreMode = true;
      expect(SafeStoreSanitizer.sanitize('كوكايين'), equals('مركب مرجعي'));
      expect(SafeStoreSanitizer.sanitize('هيروين'), equals('مركب قلوي'));
      expect(SafeStoreSanitizer.sanitize('كشف المخدرات'),
          equals('التحليل الكيميائي'));
      expect(SafeStoreSanitizer.sanitize('مواد مخدرة'),
          equals('مركبات تحليلية تعليمية'));
      expect(SafeStoreSanitizer.sanitize('حشيش'),
          equals('مركبات تحليلية تعليمية'));
      expect(SafeStoreSanitizer.sanitize('قات'), equals('مركب نباتي'));
      expect(SafeStoreSanitizer.sanitize('كشف السموم في العينة'),
          equals('تحليل كيميائي تعليمي في العينة'));
    });

    test(
        'Sanitizes mixed language strings and does not contain sensitive terms',
        () {
      SafeStoreSanitizer.safeStoreMode = true;
      final mixedText =
          'Testing cocaine, heroin, cannabis, khat, LSD, حشيش, قات, هيروين, أمفيتامين';
      final sanitized = SafeStoreSanitizer.sanitize(mixedText);

      expect(sanitized.toLowerCase().contains('heroin'), isFalse);
      expect(sanitized.toLowerCase().contains('cocaine'), isFalse);
      expect(sanitized.toLowerCase().contains('cannabis'), isFalse);
      expect(sanitized.toLowerCase().contains('khat'), isFalse);
      expect(sanitized.toLowerCase().contains('lsd'), isFalse);
      expect(sanitized.contains('حشيش'), isFalse);
      expect(sanitized.contains('قات'), isFalse);
      expect(sanitized.contains('هيروين'), isFalse);
      expect(sanitized.contains('أمفيتامين'), isFalse);

      expect(sanitized.toLowerCase(), contains('controlled compounds'));
      expect(sanitized.toLowerCase(), contains('alkaloid compounds'));
      expect(sanitized.toLowerCase(), contains('botanical compounds'));
      expect(sanitized.toLowerCase(), contains('botanical specimens'));
      expect(sanitized.toLowerCase(), contains('chemical reagents'));
      expect(sanitized, contains('مركبات تحليلية تعليمية'));
      expect(sanitized, contains('مركب نباتي'));
      expect(sanitized, contains('مركب قلوي'));
      expect(sanitized, contains('مركبات أمينية'));
    });
  });

  group('SafeStoreBackupManager Tests', () {
    test('Create and restore backups locally', () async {
      final success = await SafeStoreBackupManager.createBackup(
        reagentsData: '{"test_reagent": "original"}',
        safetyData: '{"safety": "original"}',
        referencesData: '["ref1"]',
        version: '2.0.0',
      );

      expect(success, isTrue);

      final restored = await SafeStoreBackupManager.restoreLatestBackup();
      expect(restored, isNotNull);
      expect(
          restored!['reagents_data'], equals('{"test_reagent": "original"}'));
      expect(restored['version'], equals('2.0.0'));
    });
  });

  group('RemoteConfigService Integration Tests', () {
    late RemoteConfigService rcService;
    late FakeFirebaseRemoteConfig fakeRC;

    setUp(() {
      fakeRC = FakeFirebaseRemoteConfig();
      rcService = RemoteConfigService(remoteConfig: fakeRC);
    });

    test('Default values return correctly (Review Mode defaults to true)',
        () async {
      await rcService.initialize();
      expect(rcService.appStoreReviewMode, isTrue);
      expect(rcService.safeStoreMode, isTrue);
      expect(rcService.educationalMode, isTrue);
      expect(rcService.showSensitiveNames, isFalse);
      expect(rcService.enableAiAnalysis, isFalse);
      expect(rcService.enableScientificReferences, isFalse);
    });

    test('Values return correctly when review mode is false', () async {
      fakeRC.setMockValue('app_store_review_mode', false);
      await rcService.initialize();
      expect(rcService.appStoreReviewMode, isFalse);
      expect(rcService.safeStoreMode, isFalse);
      expect(rcService.educationalMode, isFalse);
      expect(rcService.showSensitiveNames, isTrue);
      expect(rcService.enableAiAnalysis, isTrue);
      expect(rcService.enableScientificReferences, isTrue);
    });

    test('App Store Review Mode overrides other flags', () async {
      fakeRC.setMockValue('app_store_review_mode', true);
      await rcService.initialize();

      expect(rcService.appStoreReviewMode, isTrue);
      expect(rcService.safeStoreMode, isTrue);
      expect(rcService.educationalMode, isTrue);
      expect(rcService.showSensitiveNames, isFalse);
      expect(rcService.enableAiAnalysis, isFalse);
      expect(rcService.enableScientificReferences, isFalse);
      expect(rcService.hideControlledSubstances, isTrue);
    });
  });
}
