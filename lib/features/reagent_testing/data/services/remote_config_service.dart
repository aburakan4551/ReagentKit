import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../models/reagent_model.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/safe_store_sanitizer.dart';
import '../../../../core/globals.dart';

// ═════════════════════════════════════════════════════════════════════════════
// RemoteConfigService — Production-Grade
//
// Firebase Remote Config key contract:
//   • reagents_data              — JSON object: { "Marquis Test": { … }, … }
//   • safety_instructions        — JSON object: { "Marquis Test": { … }, … }
//   • references_data            — JSON object: { "Marquis Test": { "reference": […] }, … }
//   • reagent_version             — String: semantic version ("1.2.0")
//   • gemini_api_key             — String: Gemini AI key (blank = use env var)
//   • database_version           — String: scientific database version
//   • minimum_database_version   — String: minimum required database version
//   • scientific_database_hash   — String: integrity hash of the scientific dataset
//   • featured_reagents          — JSON array: list of featured reagent names
//   • maintenance_message        — String: optional maintenance banner text
//   • enable_new_reagents        — Bool: toggle for newly added reagents
//   • force_database_refresh     — Bool: forces clients to refresh the database
//   • scientific_reference_version — String: version of the references dataset
//
// ALL keys default to empty JSON so that the app never crashes if Remote
// Config has not been published yet — it falls through to local assets.
// ═════════════════════════════════════════════════════════════════════════════

class RemoteConfigService {
  // ── Key constants ──────────────────────────────────────────────────────────
  static const String _reagentsDataKey = 'reagents_data';
  static const String _safetyKey = 'safety_instructions';
  static const String _referencesDataKey = 'references_data';
  static const String _reagentVersionKey = 'reagent_version';
  static const String _geminiApiKeyKey = 'gemini_api_key';

  // Scientific database management keys
  static const String _databaseVersionKey = 'database_version';
  static const String _minimumDatabaseVersionKey = 'minimum_database_version';
  static const String _scientificDatabaseHashKey = 'scientific_database_hash';
  static const String _featuredReagentsKey = 'featured_reagents';
  static const String _maintenanceMessageKey = 'maintenance_message';
  static const String _enableNewReagentsKey = 'enable_new_reagents';
  static const String _forceDatabaseRefreshKey = 'force_database_refresh';
  static const String _scientificReferenceVersionKey =
      'scientific_reference_version';

  static const String _educationalModeKey = 'educational_mode';
  static const String _safeStoreModeKey = 'safe_store_mode';
  static const String _showSensitiveNamesKey = 'show_sensitive_names';
  static const String _enableAiAnalysisKey = 'enable_ai_analysis';
  static const String _enableScientificReferencesKey =
      'enable_scientific_references';
  static const String _enableScottTestKey = 'enable_scott_test';
  static const String _enableHighRiskTestsKey = 'enable_high_risk_tests';
  static const String _hideControlledSubstancesKey =
      'hide_controlled_substances';
  static const String _appStoreReviewModeKey = 'app_store_review_mode';

  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Defaults ensure the app boots cleanly with no published config.
      await _remoteConfig.setDefaults({
        _reagentsDataKey: '{}',
        _safetyKey: '{}',
        _referencesDataKey: '{}',
        _reagentVersionKey: '1.0.0',
        _geminiApiKeyKey: '',
        // Scientific database management defaults
        _databaseVersionKey: '1.0.0',
        _minimumDatabaseVersionKey: '1.0.0',
        _scientificDatabaseHashKey: '',
        _featuredReagentsKey: '[]',
        _maintenanceMessageKey: '',
        _enableNewReagentsKey: true,
        _forceDatabaseRefreshKey: false,
        _scientificReferenceVersionKey: '1.0.0',
        _educationalModeKey: false,
        _safeStoreModeKey: false,
        _showSensitiveNamesKey: true,
        _enableAiAnalysisKey: true,
        _enableScientificReferencesKey: true,
        _enableScottTestKey: true,
        _enableHighRiskTestsKey: true,
        _hideControlledSubstancesKey: false,
        _appStoreReviewModeKey: true,
        'paywall_enabled': true,
        'premium_upsell_enabled': true,
        'subscriptions_enabled': true,
      });

      await fetchAndActivate();
      SafeStoreSanitizer.safeStoreMode = safeStoreMode;
      SafeStoreSanitizer.appStoreReviewMode = appStoreReviewMode;
      Logger.info('✅ [RemoteConfig] Initialized successfully');
    } catch (e, st) {
      Logger.error('❌ [RemoteConfig] Initialization failed: $e',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<bool> fetchAndActivate() async {
    try {
      final oldReviewMode = appStoreReviewMode;
      final updated = await _remoteConfig.fetchAndActivate();
      final newReviewMode = appStoreReviewMode;

      if (updated || oldReviewMode != newReviewMode) {
        Logger.info('🔄 [RemoteConfig] New values activated');
        if (oldReviewMode != newReviewMode) {
          Logger.info(
              '⚠️ [RemoteConfig] App Store Review Mode changed from $oldReviewMode to $newReviewMode');
          await _handleReviewModeChange(newReviewMode);
        }
      }
      SafeStoreSanitizer.safeStoreMode = safeStoreMode;
      SafeStoreSanitizer.appStoreReviewMode = appStoreReviewMode;
      return updated;
    } catch (e, st) {
      Logger.error('❌ [RemoteConfig] fetchAndActivate failed: $e',
          error: e, stackTrace: st);
      return false;
    }
  }

  Future<bool> activate() async {
    try {
      final oldReviewMode = appStoreReviewMode;
      final success = await _remoteConfig.activate();
      final newReviewMode = appStoreReviewMode;

      if (success) {
        if (oldReviewMode != newReviewMode) {
          Logger.info(
              '⚠️ [RemoteConfig] App Store Review Mode changed from $oldReviewMode to $newReviewMode');
          await _handleReviewModeChange(newReviewMode);
        }
      }
      SafeStoreSanitizer.safeStoreMode = safeStoreMode;
      SafeStoreSanitizer.appStoreReviewMode = appStoreReviewMode;
      return success;
    } catch (e, st) {
      Logger.error('❌ [RemoteConfig] activate failed: $e',
          error: e, stackTrace: st);
      return false;
    }
  }

  Future<void> _handleReviewModeChange(bool reviewMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('scientific_dataset_cache');
      await prefs.remove('scientific_dataset_cache_prev');
      await prefs.remove('scientific_dataset_snapshot');
      await prefs.remove('cached_ai_analysis_results');
      Logger.info(
          '🧹 [RemoteConfig] Cache wiped due to Review Mode change to: $reviewMode');

      SafeStoreSanitizer.safeStoreMode = reviewMode;
      SafeStoreSanitizer.appStoreReviewMode = reviewMode;
    } catch (e) {
      Logger.error('❌ [RemoteConfig] Failed to handle review mode change: $e');
    }
  }

  // ── Reagent Data ───────────────────────────────────────────────────────────

  /// Returns true only when `reagents_data` has non-empty content.
  bool hasReagentData() {
    final raw = _remoteConfig.getString(_reagentsDataKey);
    return raw.isNotEmpty && raw != '{}';
  }

  /// Parse and return all reagents from `reagents_data`.
  ///
  /// The value must be a JSON object keyed by test name, e.g.:
  ///   { "Marquis Test": { "reagentName": "Marquis Test", … }, … }
  ///
  /// Returns an empty list (not an error) when the key is unpublished,
  /// letting [UnifiedDataService] fall back to local JSON.
  Future<List<ReagentModel>> getReagents() async {
    final raw = _remoteConfig.getString(_reagentsDataKey);

    if (raw.isEmpty || raw == '{}') {
      Logger.info(
          '⚠️ [RemoteConfig] reagents_data is empty — using local fallback');
      return [];
    }

    try {
      final Map<String, dynamic> decoded = json.decode(raw);
      final List<ReagentModel> reagents = [];
      final List<String> parseErrors = [];

      decoded.forEach((key, value) {
        try {
          if (value is! Map<String, dynamic>) {
            throw FormatException('Expected object for "$key"');
          }
          // Inject the key as reagentName when the field is absent
          final Map<String, dynamic> entry = {
            'reagentName': key,
            ...value,
          };
          reagents.add(ReagentModel.fromJson(entry));
          Logger.info('✅ [RemoteConfig] Parsed reagent: $key');
        } catch (e) {
          parseErrors.add('  • "$key": $e');
          Logger.error('❌ [RemoteConfig] Parse error for "$key": $e');
        }
      });

      if (parseErrors.isNotEmpty) {
        Logger.warning(
          '⚠️ [RemoteConfig] ${parseErrors.length} reagents skipped:\n'
          '${parseErrors.join("\n")}',
        );
      }

      Logger.info('📊 [RemoteConfig] Loaded ${reagents.length} reagents');
      return reagents;
    } catch (e, st) {
      Logger.error('❌ [RemoteConfig] Failed to decode reagents_data: $e',
          error: e, stackTrace: st);
      return [];
    }
  }

  /// Get a single reagent by name.
  Future<ReagentModel?> getReagentByName(String name) async {
    final all = await getReagents();
    try {
      return all.firstWhere(
        (r) => r.reagentName.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      Logger.info('⚠️ [RemoteConfig] Reagent "$name" not found');
      return null;
    }
  }

  // ── References Data ────────────────────────────────────────────────────────

  /// Returns scientific references for [reagentName] from Remote Config.
  ///
  /// The `references_data` key should hold:
  ///   { "Marquis Test": { "reference": ["…", "…"] }, … }
  Future<List<String>> getReferencesForReagent(String reagentName) async {
    final raw = _remoteConfig.getString(_referencesDataKey);
    if (raw.isEmpty || raw == '{}') return [];

    try {
      final Map<String, dynamic> decoded = json.decode(raw);
      final entry = decoded[reagentName];
      if (entry == null) return [];

      final refs = (entry as Map<String, dynamic>)['reference'];
      if (refs == null) return [];
      return List<String>.from(refs as List);
    } catch (e, st) {
      Logger.error(
        '❌ [RemoteConfig] getReferencesForReagent("$reagentName") failed: $e',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  // ── Safety Data ────────────────────────────────────────────────────────────

  /// Returns the raw safety JSON map from Remote Config, or `{}` on error.
  ///
  /// Used by [UnifiedDataService._loadSafetyData()] to parse safety data
  /// without coupling it to [SafetyInstructionsModel].
  Map<String, dynamic> getSafetyJsonMap() {
    final raw = _remoteConfig.getString(_safetyKey);
    if (raw.isEmpty || raw == '{}') return {};

    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (e, st) {
      Logger.error('❌ [RemoteConfig] getSafetyJsonMap failed: $e',
          error: e, stackTrace: st);
      return {};
    }
  }

  bool hasSafetyInstructions() {
    final raw = _remoteConfig.getString(_safetyKey);
    return raw.isNotEmpty && raw != '{}';
  }

  // ── Version ────────────────────────────────────────────────────────────────

  String getReagentVersion() => _remoteConfig.getString(_reagentVersionKey);

  // ── Gemini API Key ─────────────────────────────────────────────────────────

  String getGeminiApiKey() {
    final key = _remoteConfig.getString(_geminiApiKeyKey);
    if (key.isNotEmpty) {
      Logger.info('🔑 [RemoteConfig] Gemini API key loaded');
    } else {
      Logger.info('⚠️ [RemoteConfig] No Gemini API key in Remote Config');
    }
    return key;
  }

  bool hasGeminiApiKey() =>
      _remoteConfig.getString(_geminiApiKeyKey).isNotEmpty;

  /// Returns the Gemini key from Remote Config, falling back to the
  /// compile-time GEMINI_API_KEY environment variable.
  String getGeminiApiKeyWithFallback() {
    final remote = getGeminiApiKey();
    if (remote.isNotEmpty) return remote;

    const env = String.fromEnvironment('GEMINI_API_KEY');
    if (env.isNotEmpty) {
      Logger.info('🔑 [RemoteConfig] Using Gemini key from env variable');
      return env;
    }

    Logger.error('❌ [RemoteConfig] No Gemini API key found');
    return '';
  }

  // ── Scientific Database Management ────────────────────────────────────────

  /// Current scientific database version (e.g. "1.2.0").
  String get databaseVersion => _remoteConfig.getString(_databaseVersionKey);

  /// Minimum scientific database version the client is allowed to use.
  String get minimumDatabaseVersion =>
      _remoteConfig.getString(_minimumDatabaseVersionKey);

  /// Integrity hash of the scientific dataset. Empty string when unpublished.
  String get scientificDatabaseHash =>
      _remoteConfig.getString(_scientificDatabaseHashKey);

  /// Optional maintenance banner text shown to the user. Empty when no banner.
  String get maintenanceMessage =>
      _remoteConfig.getString(_maintenanceMessageKey);

  /// True when newly added reagents should be surfaced to the user.
  bool get enableNewReagents => _remoteConfig.getBool(_enableNewReagentsKey);

  /// True when the backend is forcing every client to refresh its database.
  bool get forceDatabaseRefresh =>
      _remoteConfig.getBool(_forceDatabaseRefreshKey);

  /// Version of the scientific references dataset.
  String get scientificReferenceVersion =>
      _remoteConfig.getString(_scientificReferenceVersionKey);

  /// Returns the list of featured reagent names from Remote Config.
  /// Empty list when the key is unpublished or malformed.
  List<String> getFeaturedReagents() {
    final raw = _remoteConfig.getString(_featuredReagentsKey);
    if (raw.isEmpty || raw == '[]') return const [];
    try {
      final decoded = json.decode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (e, st) {
      Logger.error('❌ [RemoteConfig] getFeaturedReagents failed: $e',
          error: e, stackTrace: st);
    }
    return const [];
  }

  /// True when the client database version is older than the minimum required.
  /// Used to nudge the user to refresh the scientific dataset.
  bool requiresDatabaseUpdate() {
    final current = databaseVersion;
    final minimum = minimumDatabaseVersion;
    if (current.isEmpty || minimum.isEmpty) return false;
    return _compareSemver(current, minimum) < 0;
  }

  int _compareSemver(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va.compareTo(vb);
    }
    return 0;
  }

  // ── Safe Store Mode Getters ────────────────────────────────────────────────

  bool get appStoreReviewMode => _remoteConfig.getBool(_appStoreReviewModeKey);

  bool get safeStoreMode {
    final mode = _remoteConfig.getBool(_safeStoreModeKey) || appStoreReviewMode;
    // Set sanitizer mode dynamically
    SafeStoreSanitizer.safeStoreMode = mode;
    return mode;
  }

  bool get educationalMode =>
      _remoteConfig.getBool(_educationalModeKey) || appStoreReviewMode;

  bool get showSensitiveNames => appStoreReviewMode
      ? false
      : _remoteConfig.getBool(_showSensitiveNamesKey);

  bool get enableAiAnalysis =>
      appStoreReviewMode ? false : _remoteConfig.getBool(_enableAiAnalysisKey);

  bool get enableScientificReferences => appStoreReviewMode
      ? false
      : _remoteConfig.getBool(_enableScientificReferencesKey);

  bool get enableScottTest =>
      appStoreReviewMode ? false : _remoteConfig.getBool(_enableScottTestKey);

  bool get enableHighRiskTests => appStoreReviewMode
      ? false
      : _remoteConfig.getBool(_enableHighRiskTestsKey);

  bool get hideControlledSubstances => appStoreReviewMode
      ? true
      : _remoteConfig.getBool(_hideControlledSubstancesKey);

  // ── Review Mode Overrides ──────────────────────────────────────────────────

  bool get paywallEnabled =>
      isPremiumReviewMode ? false : _remoteConfig.getBool('paywall_enabled');

  bool get premiumUpsellEnabled => isPremiumReviewMode
      ? false
      : _remoteConfig.getBool('premium_upsell_enabled');

  bool get subscriptionsEnabled => isPremiumReviewMode
      ? false
      : _remoteConfig.getBool('subscriptions_enabled');

  // ── Real-time updates ──────────────────────────────────────────────────────

  Stream<RemoteConfigUpdate> onConfigUpdated() => _remoteConfig.onConfigUpdated;
}
