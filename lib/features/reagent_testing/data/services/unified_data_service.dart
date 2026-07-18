import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart'; // for compute
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import '../models/reagent_test_model.dart';
import '../models/drug_result_model.dart';
import '../../../../scientific_engine/safe_parsers.dart';
import '../../../../scientific_engine/validation_profile.dart';
import '../../../../scientific_engine/dataset_migration.dart';
import '../../../../core/services/crash_analytics.dart';
import 'remote_config_service.dart';
import '../../../../core/services/safe_store_sanitizer.dart';
import '../../../../core/services/safe_store_backup_manager.dart';
import '../../../../core/services/firestore_scientific_service.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Enums & Value Objects
// ═════════════════════════════════════════════════════════════════════════════

enum DataSource { firebase, local, staleCache }

enum DataHealthStatus {
  healthy,
  degraded,
  fallback,
  corrupted,
  empty,
}

enum DatasetLifecycleState {
  idle,
  loading,
  recovering,
  healthy,
  degraded,
  fallback,
  corrupted,
}

enum ScientificIntegrity {
  verified,
  partial,
  migrated,
  fallback,
}

enum WarningSeverity {
  info,
  warning,
  critical,
}

/// Professional Diagnostics Object for Dataset Validation and Stats
class DatasetDiagnostics {
  final int rawItems;
  final int parsedItems;
  final int skippedItems;
  final int invalidReferences;
  final int invalidColors;
  final bool usedFallback;
  final String datasetVersion;

  const DatasetDiagnostics({
    this.rawItems = 0,
    this.parsedItems = 0,
    this.skippedItems = 0,
    this.invalidReferences = 0,
    this.invalidColors = 0,
    this.usedFallback = false,
    this.datasetVersion = 'unknown',
  });

  Map<String, dynamic> toJson() => {
    'rawItems': rawItems,
    'parsedItems': parsedItems,
    'skippedItems': skippedItems,
    'invalidReferences': invalidReferences,
    'invalidColors': invalidColors,
    'usedFallback': usedFallback,
    'datasetVersion': datasetVersion,
  };

  @override
  String toString() {
    return 'DatasetDiagnostics(raw: $rawItems, parsed: $parsedItems, skipped: $skippedItems, '
        'invalidRefs: $invalidReferences, invalidColors: $invalidColors, fallback: $usedFallback, version: $datasetVersion)';
  }
}

// ─── DatasetMetadata ─────────────────────────────────────────────────────────

class DatasetMetadata {
  final String source;
  final String author;
  final DateTime generatedAt;
  final String scientificRevision;
  final DateTime expiresAt;

  const DatasetMetadata({
    required this.source,
    required this.author,
    required this.generatedAt,
    required this.scientificRevision,
    required this.expiresAt,
  });

  factory DatasetMetadata.fromJson(Map<String, dynamic> json) {
    return DatasetMetadata(
      source: json['source']?.toString() ?? 'unknown',
      author: json['author']?.toString() ?? 'unknown',
      generatedAt: DateTime.tryParse(json['generatedAt']?.toString() ?? '') ?? DateTime.now(),
      scientificRevision: json['scientificRevision']?.toString() ?? '1.0.0',
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 365)),
    );
  }
}

// ─── ScientificFeatureFlags ──────────────────────────────────────────────────

class ScientificFeatureFlags {
  final bool enableMigration;
  final bool enableFallback;

  const ScientificFeatureFlags({
    this.enableMigration = true,
    this.enableFallback = true,
  });
}

// ─── DatasetCircuitBreaker ───────────────────────────────────────────────────

class DatasetCircuitBreaker {
  bool isOpen = false;
  DateTime? openedAt;
  int failureCount = 0;
  static const int failureThreshold = 3;
  static const Duration cooldownDuration = Duration(minutes: 5);

  void recordFailure() {
    failureCount++;
    if (failureCount >= failureThreshold) {
      isOpen = true;
      openedAt = DateTime.now();
      developer.log('🚨 Circuit breaker opened!', name: 'CircuitBreaker');
    }
  }

  bool get isBlocked {
    if (!isOpen) return false;
    if (openedAt == null) return false;
    final now = DateTime.now();
    if (now.difference(openedAt!) > cooldownDuration) {
      isOpen = false;
      failureCount = 0;
      openedAt = null;
      developer.log('🔄 Circuit breaker reset (cooldown expired)', name: 'CircuitBreaker');
      return false;
    }
    return true;
  }

  void reset() {
    isOpen = false;
    failureCount = 0;
    openedAt = null;
  }
}

// ─── DatasetTelemetryEvent ───────────────────────────────────────────────────

class DatasetTelemetryEvent {
  final String eventName;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  DatasetTelemetryEvent({
    required this.eventName,
    required this.metadata,
  }) : timestamp = DateTime.now();
}

// ─── DataSnapshot ────────────────────────────────────────────────────────────

/// Everything the UI needs to know about the current data load result.
@immutable
class DataSnapshot {
  final UnmodifiableListView<ReagentTestModel> reagents;
  final DataSource source;
  final DataHealthStatus health;
  final String version;
  final DateTime loadedAt;
  final String? warningMessage;
  final DatasetDiagnostics diagnostics;
  final DatasetLifecycleState lifecycleState;
  final ScientificIntegrity integrity;
  final WarningSeverity warningSeverity;
  final DatasetMetadata? metadata;
  final DatasetLineage? lineage;

  const DataSnapshot({
    required this.reagents,
    required this.source,
    required this.health,
    required this.version,
    required this.loadedAt,
    required this.diagnostics,
    required this.lifecycleState,
    required this.integrity,
    required this.warningSeverity,
    this.warningMessage,
    this.metadata,
    this.lineage,
  });

  bool get isFirebase  => source == DataSource.firebase;
  bool get isFallback  => source == DataSource.local || source == DataSource.staleCache;
  bool get hasWarning  => warningMessage != null;
}

// ─── ReagentSafetyData ───────────────────────────────────────────────────────

class ReagentSafetyData {
  final String reagentName;
  final String safetyLevel;
  final List<String> requiredEquipment;
  final List<String> handlingProcedures;
  final List<String> specificHazards;
  final List<String> storageRequirements;

  const ReagentSafetyData({
    required this.reagentName,
    required this.safetyLevel,
    required this.requiredEquipment,
    required this.handlingProcedures,
    required this.specificHazards,
    required this.storageRequirements,
  });

  factory ReagentSafetyData.fromJson(
    String name,
    Map<String, dynamic> jsonMap,
  ) {
    List<String> asList(String key) =>
        (jsonMap[key] as List? ?? []).map((e) => e.toString()).toList();

    return ReagentSafetyData(
      reagentName:         name,
      safetyLevel:         jsonMap['safetyLevel']?.toString() ?? 'MEDIUM',
      requiredEquipment:   asList('requiredEquipment'),
      handlingProcedures:  asList('handlingProcedures'),
      specificHazards:     asList('specificHazards'),
      storageRequirements: asList('storageRequirements'),
    );
  }
}

// ─── DatasetSource Abstraction ───────────────────────────────────────────────

abstract class DatasetSource {
  Future<String> load();
}

class LocalAssetDatasetSource implements DatasetSource {
  final String assetPath;
  const LocalAssetDatasetSource(this.assetPath);

  @override
  Future<String> load() async {
    return await rootBundle.loadString(assetPath);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Isolate Parsers & Input/Output Structures
// ═════════════════════════════════════════════════════════════════════════════

class ParseParams {
  final String rawJson;
  final ValidationProfile profile;
  const ParseParams(this.rawJson, this.profile);
}

class ParseOutput {
  final List<Map<String, dynamic>> parsedReagents;
  final int rawItemsCount;
  final int skippedItemsCount;
  final int invalidColorsCount;
  final int invalidReferencesCount;
  final String version;
  final String error;

  const ParseOutput({
    required this.parsedReagents,
    required this.rawItemsCount,
    required this.skippedItemsCount,
    required this.invalidColorsCount,
    required this.invalidReferencesCount,
    required this.version,
    this.error = '',
  });
}

/// Pure Dart parsing logic executed in a background Isolate to prevent UI freezes
ParseOutput parseScientificDatasetIsolate(ParseParams params) {
  final rawJson = params.rawJson;
  final profile = params.profile;
  try {
    // 1. Enforce payload size budget (5MB)
    if (rawJson.length > 5 * 1024 * 1024) {
      return ParseOutput(
        parsedReagents: [],
        rawItemsCount: 0,
        skippedItemsCount: 0,
        invalidColorsCount: 0,
        invalidReferencesCount: 0,
        version: 'unknown',
        error: 'Payload size exceeds budget (5MB limit)',
      );
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    } on FormatException catch (e) {
      return ParseOutput(
        parsedReagents: [],
        rawItemsCount: 0,
        skippedItemsCount: 0,
        invalidColorsCount: 0,
        invalidReferencesCount: 0,
        version: 'unknown',
        error: 'JSON decode FormatException: ${e.message}',
      );
    } catch (e) {
      return ParseOutput(
        parsedReagents: [],
        rawItemsCount: 0,
        skippedItemsCount: 0,
        invalidColorsCount: 0,
        invalidReferencesCount: 0,
        version: 'unknown',
        error: 'JSON decode failed: $e',
      );
    }

    final version = (decoded['dataset_version'] ??
            decoded['schemaVersion'] ??
            decoded['databaseVersion'] ??
            decoded['version'] ??
            'unknown')
        .toString();

    final reagentsData = decoded['reagents'];
    
    // Enforce reagent count budget (500 limit)
    int rawItems = 0;
    if (reagentsData is Map) {
      rawItems = reagentsData.length;
    } else if (reagentsData is List) {
      rawItems = reagentsData.length;
    }
    if (rawItems > 500) {
      return ParseOutput(
        parsedReagents: [],
        rawItemsCount: rawItems,
        skippedItemsCount: 0,
        invalidColorsCount: 0,
        invalidReferencesCount: 0,
        version: version,
        error: 'Reagent count exceeds budget (500 limit)',
      );
    }

    final List<Map<String, dynamic>> parsedList = [];
    int skippedItems = 0;
    int invalidColors = 0;
    int invalidReferences = 0;
    int totalReferencesCount = 0;

    void processReagent(String key, Map<String, dynamic> val) {
      // Dynamically inject missing keys for compatibility with flat reagents.json format
      if (val['id'] == null || val['id'].toString().trim().isEmpty) {
        val['id'] = key.toLowerCase().replaceAll(' ', '_');
      }
      if (val['reagentName'] == null || val['reagentName'].toString().trim().isEmpty) {
        val['reagentName'] = key;
      }
      if (val['category'] == null || val['category'].toString().trim().isEmpty) {
        val['category'] = 'Primary Tests';
      }

      final refs = val['references'] ?? val['reference'] ?? val['refs'];
      if (refs is List) {
        totalReferencesCount += refs.length;
        for (final ref in refs) {
          if (ref == null || ref.toString().trim().isEmpty) {
            invalidReferences++;
          }
        }
      }

      final results = val['reactionResults'] ?? val['drugResults'] ?? val['results'];
      if (results is List) {
        for (final res in results) {
          if (res is Map<String, dynamic>) {
            final colorStr = res['color']?.toString() ?? '';
            if (colorStr.isNotEmpty) {
              final parsedColor = SafeColorParser.parseRobustColor(colorStr);
              if (parsedColor.r == 128 && parsedColor.g == 128 && parsedColor.b == 128) {
                invalidColors++;
              }
            }
          }
        }
      }

      // Check validation constraints
      final model = ReagentTestModel.fromJson(val, profile: profile);
      parsedList.add(model.toJson());
    }

    if (reagentsData is Map<String, dynamic>) {
      reagentsData.forEach((key, val) {
        if (val is Map<String, dynamic>) {
          try {
            processReagent(key, val);
          } catch (e, st) {
            skippedItems++;
            developer.log(
              'Failed to parse reagent "$key"',
              error: e,
              stackTrace: st,
              name: 'ScientificParser',
            );
          }
        } else {
          skippedItems++;
        }
      });
    } else if (reagentsData is List) {
      for (final val in reagentsData) {
        if (val is Map<String, dynamic>) {
          try {
            final key = val['id']?.toString() ?? 'unknown';
            processReagent(key, val);
          } catch (e, st) {
            skippedItems++;
            developer.log(
              'Failed to parse reagent in list',
              error: e,
              stackTrace: st,
              name: 'ScientificParser',
            );
          }
        } else {
          skippedItems++;
        }
      }
    } else {
      if (decoded.containsKey('reagents') == false) {
        var hasReagentLikeStructure = false;
        decoded.forEach((key, val) {
          if (val is Map<String, dynamic> && (val.containsKey('reagentName') || val.containsKey('name'))) {
            hasReagentLikeStructure = true;
          }
        });

        if (hasReagentLikeStructure) {
          decoded.forEach((key, val) {
            if (val is Map<String, dynamic>) {
              try {
                processReagent(key, val);
              } catch (e) {
                skippedItems++;
              }
            } else {
              skippedItems++;
            }
          });
        }
      }
    }

    // Enforce total references count budget (1000 limit)
    if (totalReferencesCount > 1000) {
      return ParseOutput(
        parsedReagents: [],
        rawItemsCount: rawItems,
        skippedItemsCount: 0,
        invalidColorsCount: 0,
        invalidReferencesCount: 0,
        version: version,
        error: 'Total references exceed budget (1000 limit)',
      );
    }

    return ParseOutput(
      parsedReagents: parsedList,
      rawItemsCount: rawItems,
      skippedItemsCount: skippedItems,
      invalidColorsCount: invalidColors,
      invalidReferencesCount: invalidReferences,
      version: version,
    );
  } catch (e, st) {
    developer.log(
      'Isolate parsing critical error',
      error: e,
      stackTrace: st,
      name: 'ScientificParser',
    );
    return ParseOutput(
      parsedReagents: [],
      rawItemsCount: 0,
      skippedItemsCount: 0,
      invalidColorsCount: 0,
      invalidReferencesCount: 0,
      version: 'unknown',
      error: e.toString(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// UnifiedDataService — Resilient Pipeline Load
// ═════════════════════════════════════════════════════════════════════════════

class UnifiedDataService {
  final RemoteConfigService? _remoteConfig;
  // ignore: unused_field
  final FirestoreScientificService? _firestoreScientific;
  // ignore: unused_field
  final dynamic _connectivity;

  List<ReagentTestModel>? _cachedReagents;
  String _cacheVersion = '1.0.0';
  bool _initialized = false;
  bool _firebaseEverLoaded = false;

  // Bundled asset used only as the last emergency fallback (Layer 5).
  // app_store_review_mode no longer selects the dataset; reagents.json is the
  // sole fallback so Remote Config is the single primary source.
  static const String _fallbackAsset = 'assets/data/reagents.json';

  final _snapshotController = StreamController<DataSnapshot>.broadcast();
  Stream<DataSnapshot> get onSnapshot => _snapshotController.stream;

  DataSource get lastSource => _lastDataSource;
  DataSource _lastDataSource = DataSource.local;
  bool get hasCachedData => _cachedReagents != null;
  bool get firebaseEverLoaded => _firebaseEverLoaded;
  String get cacheVersion => _cacheVersion;

  // New Lifecycle State and warning severity tracking
  DatasetLifecycleState _currentLifecycleState = DatasetLifecycleState.idle;
  DatasetLifecycleState get lifecycleState => _currentLifecycleState;

  WarningSeverity _currentWarningSeverity = WarningSeverity.info;
  WarningSeverity get warningSeverity => _currentWarningSeverity;

  // Watchdog variables
  Timer? _recoveryTimer;
  int _recoveryAttemptsInSession = 0;
  static const int maxRecoveryAttemptsPerSession = 5;
  static const Duration recoveryInterval = Duration(minutes: 5);

  // Circuit breaker & Transaction Lock
  final DatasetCircuitBreaker _circuitBreaker = DatasetCircuitBreaker();
  Future<DataSnapshot>? _currentLoadFuture;

  // Telemetry buffer & constants
  final List<DatasetTelemetryEvent> _telemetryBatch = [];
  static const double _warningSampleRate = 0.2;
  static const int _telemetryBatchSize = 10;

  // Migrator
  final DatasetMigrator _migrator = const DatasetMigrator([LegacyToV1Migration()]);

  UnifiedDataService({
    dynamic remoteConfig,
    dynamic connectivity,
    FirestoreScientificService? firestoreScientific,
  })  : _remoteConfig = remoteConfig,
        _connectivity = connectivity,
        _firestoreScientific = firestoreScientific;

  /// Initialises the dataset and validates integrity in the background
  Future<void> initialize() async {
    if (_initialized) return;
    developer.log('🚀 [UnifiedDataService] Initializing local scientific dataset...', name: 'ScientificParser');
    try {
      await loadPipeline();
      _initialized = true;
      developer.log('✅ [UnifiedDataService] Initialization complete', name: 'ScientificParser');
    } catch (e, st) {
      developer.log('❌ [UnifiedDataService] Initialization failed: $e', error: e, stackTrace: st, name: 'ScientificParser');
    }
  }

  /// Compatibility method: loads local assets since Remote Config is removed
  Future<DataSnapshot> fetchFromRemoteConfig() async {
    developer.log('☁️ [UnifiedDataService] Remote config bypass: loading from assets...', name: 'ScientificParser');
    return loadPipeline();
  }

  /// Compatibility method: loads from pipeline
  Future<DataSnapshot> loadFromAssets() async {
    return loadPipeline();
  }

  /// Unified loading pipeline with transaction locking and 5 recovery layers
  Future<DataSnapshot> loadPipeline({
    bool forceAssetReload = false,
    bool clearCache = false,
    ValidationProfile profile = ValidationProfile.balanced,
  }) {
    if (_currentLoadFuture != null && !forceAssetReload) {
      return _currentLoadFuture!;
    }
    final future = _loadPipelineImpl(
      forceAssetReload: forceAssetReload,
      clearCache: clearCache,
      profile: profile,
    );
    _currentLoadFuture = future;
    return future.whenComplete(() {
      _currentLoadFuture = null;
    });
  }

  Future<DataSnapshot> _loadPipelineImpl({
    bool forceAssetReload = false,
    bool clearCache = false,
    ValidationProfile profile = ValidationProfile.balanced,
  }) async {
    developer.log('Starting loadPipelineImpl (forceAssetReload: $forceAssetReload, clearCache: $clearCache)', name: 'ScientificParser');

    // ── Remote Config Sync Check ─────────────────────────────────────────────
    // Check if we need to refresh from Firestore based on Remote Config
    bool shouldForceRefresh = false;
    String remoteDatabaseVersion = '';
    String remoteDatabaseHash = '';
    
    if (_remoteConfig != null) {
      shouldForceRefresh = _remoteConfig.forceDatabaseRefresh;
      remoteDatabaseVersion = _remoteConfig.databaseVersion;
      remoteDatabaseHash = _remoteConfig.scientificDatabaseHash;
      
      if (shouldForceRefresh) {
        developer.log('🔄 [UnifiedDataService] Remote Config force_database_refresh=true - forcing Firestore refresh', name: 'ScientificParser');
      }
      if (remoteDatabaseVersion.isNotEmpty) {
        developer.log('📦 [UnifiedDataService] Remote Config database_version: $remoteDatabaseVersion', name: 'ScientificParser');
      }
      if (remoteDatabaseHash.isNotEmpty) {
        developer.log('🔐 [UnifiedDataService] Remote Config scientific_database_hash: $remoteDatabaseHash', name: 'ScientificParser');
      }
    }

    final isSafeStore = _remoteConfig?.safeStoreMode ?? SafeStoreSanitizer.safeStoreMode;
    final prefs = await SharedPreferences.getInstance();
    if (clearCache || isSafeStore || shouldForceRefresh) {
      try {
        await prefs.remove('scientific_dataset_cache');
        await prefs.remove('scientific_dataset_cache_prev');
        await prefs.remove('scientific_dataset_snapshot');
        await prefs.remove('scientific_dataset_hash'); // Remove stored hash
        developer.log('Local caches cleared due to Safe Store Mode, force clear, or Remote Config force refresh.', name: 'ScientificParser');
      } catch (e) {
        developer.log('Failed to clear cache: $e', name: 'ScientificParser');
      }
    }

    // Check if cached hash matches Remote Config hash (cache is up-to-date)
    if (remoteDatabaseHash.isNotEmpty) {
      final cachedHash = prefs.getString('scientific_dataset_hash');
      if (cachedHash == remoteDatabaseHash) {
        developer.log('✅ [UnifiedDataService] Local cache hash matches Remote Config - dataset is current', name: 'ScientificParser');
      }
    }

    // Circuit Breaker Check
    if (_circuitBreaker.isBlocked) {
      developer.log('⚠️ Circuit breaker is active. Skipping load pipeline and using fallback.', name: 'CircuitBreaker');
      _currentLifecycleState = DatasetLifecycleState.fallback;
      _currentWarningSeverity = WarningSeverity.critical;
      final snapshot = _createFallbackSnapshot(
        source: DataSource.local,
        lifecycleState: DatasetLifecycleState.fallback,
        integrity: ScientificIntegrity.fallback,
        warningSeverity: WarningSeverity.critical,
        warningMsg: 'Circuit breaker active. Primary parsing bypassed.',
      );
      _traceLayer('Circuit Breaker Fallback', snapshot);
      return snapshot;
    }

    _currentLifecycleState = DatasetLifecycleState.loading;

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 1: Remote Config - Primary Source (reagents_data key)
    // ─────────────────────────────────────────────────────────────────────────
    try {
      developer.log('[DATA SOURCE] Attempting Remote Config: reagents_data...', name: 'ScientificParser');

      final raw = _remoteConfig?.getReagentsDataRaw();
      if (raw == null) {
        throw FormatException('reagents_data is empty or missing from Remote Config');
      }
      developer.log('[DATA SOURCE] Remote Config reagents_data retrieved', name: 'ScientificParser');

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final (migratedJson, appliedMigrations) = _migrator.migrate(decoded);
      final migratedRaw = jsonEncode(migratedJson);

      final parseOutput = await _verifyAndParse(migratedRaw, profile);

      await SafeStoreBackupManager.createBackup(
        reagentsData: migratedRaw,
        safetyData: '{}',
        referencesData: '{}',
        version: parseOutput.version,
      );

      final List<ReagentTestModel> reagentsList = parseOutput.parsedReagents
          .map((e) => ReagentTestModel.fromJson(e, profile: profile))
          .toList();

      reagentsList.sort((a, b) => a.id.compareTo(b.id));

      _circuitBreaker.reset();
      _currentLifecycleState = parseOutput.skippedItemsCount > 0
          ? DatasetLifecycleState.degraded
          : DatasetLifecycleState.healthy;

      final currentCache = prefs.getString('scientific_dataset_cache');
      if (currentCache != null && currentCache != migratedRaw) {
        await prefs.setString('scientific_dataset_cache_prev', currentCache);
      }

      await _atomicWriteCache('scientific_dataset_cache', migratedRaw);

      if (remoteDatabaseHash.isNotEmpty) {
        await prefs.setString('scientific_dataset_hash', remoteDatabaseHash);
        developer.log('💾 [UnifiedDataService] Stored scientific_dataset_hash for sync validation', name: 'ScientificParser');
      }

      final snapshotMap = {
        'version': parseOutput.version,
        'reagents': parseOutput.parsedReagents,
        'generatedAt': DateTime.now().toIso8601String(),
      };
      final compressed = compressGzip(jsonEncode(snapshotMap));
      await prefs.setString('scientific_dataset_snapshot', compressed);

      final metadata = DatasetMetadata(
        source: 'remote_config',
        author: decoded['author']?.toString() ?? 'Remote Config',
        generatedAt: DateTime.tryParse(decoded['generatedAt']?.toString() ?? '') ?? DateTime.now(),
        scientificRevision: decoded['scientificRevision']?.toString() ?? parseOutput.version,
        expiresAt: DateTime.tryParse(decoded['expiresAt']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 365)),
      );

      final lineage = DatasetLineage(
        parentDataset: decoded['version']?.toString() ?? 'unknown',
        migrationsApplied: appliedMigrations,
      );

      _cachedReagents = reagentsList;
      _cacheVersion = parseOutput.version;
      _lastDataSource = DataSource.firebase;
      _firebaseEverLoaded = true;

      final diagnostics = DatasetDiagnostics(
        rawItems: parseOutput.rawItemsCount,
        parsedItems: reagentsList.length,
        skippedItems: parseOutput.skippedItemsCount,
        invalidReferences: parseOutput.invalidReferencesCount,
        invalidColors: parseOutput.invalidColorsCount,
        usedFallback: false,
        datasetVersion: parseOutput.version,
      );

      var integrity = appliedMigrations.isNotEmpty
          ? ScientificIntegrity.migrated
          : ScientificIntegrity.verified;

      var warningSeverity = WarningSeverity.info;
      String? warningMsg = parseOutput.skippedItemsCount > 0
          ? 'Loaded with degraded status: ${parseOutput.skippedItemsCount} items skipped.'
          : null;

      final age = DateTime.now().difference(metadata.generatedAt);
      if (age.inDays > 90) {
        _currentLifecycleState = DatasetLifecycleState.degraded;
        warningSeverity = WarningSeverity.critical;
        warningMsg = 'Dataset is older than 90 days (critical degradation).';
      } else if (age.inDays > 30) {
        integrity = ScientificIntegrity.partial;
        warningSeverity = WarningSeverity.warning;
        warningMsg = 'Dataset is older than 30 days (warnings generated).';
      }

      _currentWarningSeverity = warningSeverity;

      final snapshot = _makeSnapshot(
        reagents: reagentsList,
        source: DataSource.firebase,
        health: parseOutput.skippedItemsCount > 0 ? DataHealthStatus.degraded : DataHealthStatus.healthy,
        version: parseOutput.version,
        diagnostics: diagnostics,
        lifecycleState: _currentLifecycleState,
        integrity: integrity,
        warningSeverity: warningSeverity,
        warningMessage: warningMsg,
        metadata: metadata,
        lineage: lineage,
      );

      _traceLayer('Layer 1 Remote Config', snapshot);
      _snapshotController.add(snapshot);
      stopRecoveryWatchdog();
      _logTelemetry('dataset_load_success', {'source': 'remote_config', 'version': parseOutput.version});
      developer.log('[DATA SOURCE] ✅ Loaded ${reagentsList.length} reagents from Remote Config', name: 'ScientificParser');
      return snapshot;

    } catch (e, st) {
      developer.log('[DATA SOURCE] Remote Config load failed, falling back to local cache...', error: e, stackTrace: st, name: 'ScientificParser');
      _logTelemetry('dataset_load_warning', {'error': e.toString(), 'layer': 'remote_config'}, isWarning: true);
      _circuitBreaker.recordFailure();
      CrashAnalytics.recordError(e, st, reason: 'Remote Config scientific dataset load failed');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 2: Cache Recovery Source
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final cachedJson = prefs.getString('scientific_dataset_cache');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        final (migratedJson, appliedMigrations) = _migrator.migrate(decoded);
        final migratedRaw = jsonEncode(migratedJson);

        final parseOutput = await _verifyAndParse(migratedRaw, profile);
        final List<ReagentTestModel> reagentsList = parseOutput.parsedReagents
            .map((e) => ReagentTestModel.fromJson(e, profile: profile))
            .toList();

        reagentsList.sort((a, b) => a.id.compareTo(b.id));

        _currentLifecycleState = DatasetLifecycleState.fallback;
        _currentWarningSeverity = WarningSeverity.warning;
        _cachedReagents = reagentsList;
        _cacheVersion = parseOutput.version;
        _lastDataSource = DataSource.staleCache;

        final diagnostics = DatasetDiagnostics(
          rawItems: parseOutput.rawItemsCount,
          parsedItems: reagentsList.length,
          skippedItems: parseOutput.skippedItemsCount,
          invalidReferences: parseOutput.invalidReferencesCount,
          invalidColors: parseOutput.invalidColorsCount,
          usedFallback: true,
          datasetVersion: parseOutput.version,
        );

        final metadata = DatasetMetadata(
          source: 'cache',
          author: decoded['author']?.toString() ?? 'System',
          generatedAt: DateTime.tryParse(decoded['generatedAt']?.toString() ?? '') ?? DateTime.now(),
          scientificRevision: decoded['scientificRevision']?.toString() ?? parseOutput.version,
          expiresAt: DateTime.tryParse(decoded['expiresAt']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 365)),
        );

        final snapshot = _makeSnapshot(
          reagents: reagentsList,
          source: DataSource.staleCache,
          health: DataHealthStatus.fallback,
          version: parseOutput.version,
          diagnostics: diagnostics,
          lifecycleState: DatasetLifecycleState.fallback,
          integrity: ScientificIntegrity.fallback,
          warningSeverity: WarningSeverity.warning,
          warningMessage: 'Primary asset failed. Loaded from local recovery cache.',
          metadata: metadata,
        );

        _traceLayer('Layer 2 Cache Recovery', snapshot);
        _snapshotController.add(snapshot);
        startRecoveryWatchdog();
        _logTelemetry('dataset_load_success', {'source': 'cache', 'version': parseOutput.version});
        return snapshot;
      }
    } catch (e, st) {
      developer.log('Cache recovery failed, attempting Previous Cache...', error: e, stackTrace: st, name: 'ScientificParser');
      _logTelemetry('dataset_load_warning', {'error': e.toString(), 'layer': 'cache'}, isWarning: true);
      _circuitBreaker.recordFailure();
      CrashAnalytics.recordError(e, st, reason: 'Cache recovery of scientific dataset failed');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 3: Previous Cache
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final prevJson = prefs.getString('scientific_dataset_cache_prev');
      if (prevJson != null && prevJson.isNotEmpty) {
        final decoded = jsonDecode(prevJson) as Map<String, dynamic>;
        final (migratedJson, appliedMigrations) = _migrator.migrate(decoded);
        final migratedRaw = jsonEncode(migratedJson);

        final parseOutput = await _verifyAndParse(migratedRaw, profile);
        final List<ReagentTestModel> reagentsList = parseOutput.parsedReagents
            .map((e) => ReagentTestModel.fromJson(e, profile: profile))
            .toList();

        reagentsList.sort((a, b) => a.id.compareTo(b.id));

        _currentLifecycleState = DatasetLifecycleState.fallback;
        _currentWarningSeverity = WarningSeverity.warning;
        _cachedReagents = reagentsList;
        _cacheVersion = parseOutput.version;
        _lastDataSource = DataSource.staleCache;

        final diagnostics = DatasetDiagnostics(
          rawItems: parseOutput.rawItemsCount,
          parsedItems: reagentsList.length,
          skippedItems: parseOutput.skippedItemsCount,
          invalidReferences: parseOutput.invalidReferencesCount,
          invalidColors: parseOutput.invalidColorsCount,
          usedFallback: true,
          datasetVersion: parseOutput.version,
        );

        final snapshot = _makeSnapshot(
          reagents: reagentsList,
          source: DataSource.staleCache,
          health: DataHealthStatus.fallback,
          version: parseOutput.version,
          diagnostics: diagnostics,
          lifecycleState: DatasetLifecycleState.fallback,
          integrity: ScientificIntegrity.fallback,
          warningSeverity: WarningSeverity.warning,
          warningMessage: 'Primary & current cache failed. Loaded from previous cache.',
);

        _traceLayer('Layer 6 Emergency In-Memory', snapshot);
        _snapshotController.add(snapshot);
        startRecoveryWatchdog();
        _logTelemetry('dataset_load_success', {'source': 'prev_cache', 'version': parseOutput.version});
        return snapshot;
      }
    } catch (e, st) {
      developer.log('Previous cache failed, attempting Gzip Snapshot...', error: e, stackTrace: st, name: 'ScientificParser');
      _logTelemetry('dataset_load_warning', {'error': e.toString(), 'layer': 'prev_cache'}, isWarning: true);
      _circuitBreaker.recordFailure();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 4: Snapshot (Gzip Compressed)
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final compressedBase64 = prefs.getString('scientific_dataset_snapshot');
      if (compressedBase64 != null && compressedBase64.isNotEmpty) {
        final decompressed = decompressGzip(compressedBase64);
        final decoded = jsonDecode(decompressed) as Map<String, dynamic>;
        final version = decoded['version']?.toString() ?? 'unknown';
        final rawReagents = decoded['reagents'] as List;

        final List<ReagentTestModel> reagentsList = [];
        for (final r in rawReagents) {
          reagentsList.add(ReagentTestModel.fromJson(r as Map<String, dynamic>, profile: profile));
        }

        reagentsList.sort((a, b) => a.id.compareTo(b.id));

        _currentLifecycleState = DatasetLifecycleState.fallback;
        _currentWarningSeverity = WarningSeverity.warning;
        _cachedReagents = reagentsList;
        _cacheVersion = version;
        _lastDataSource = DataSource.staleCache;

        final diagnostics = DatasetDiagnostics(
          rawItems: reagentsList.length,
          parsedItems: reagentsList.length,
          skippedItems: 0,
          invalidReferences: 0,
          invalidColors: 0,
          usedFallback: true,
          datasetVersion: version,
        );

        final snapshot = _makeSnapshot(
          reagents: reagentsList,
          source: DataSource.staleCache,
          health: DataHealthStatus.fallback,
          version: version,
          diagnostics: diagnostics,
          lifecycleState: DatasetLifecycleState.fallback,
          integrity: ScientificIntegrity.fallback,
          warningSeverity: WarningSeverity.warning,
          warningMessage: 'Loaded from decompressed snapshot.',
        );

        _traceLayer('Layer 4 Snapshot', snapshot);
        _snapshotController.add(snapshot);
        startRecoveryWatchdog();
        _logTelemetry('dataset_load_success', {'source': 'gzip_snapshot', 'version': version});
        return snapshot;
      }
    } catch (e, st) {
      developer.log('Snapshot recovery failed, falling back to emergency dataset...', error: e, stackTrace: st, name: 'ScientificParser');
      _logTelemetry('dataset_load_warning', {'error': e.toString(), 'layer': 'snapshot'}, isWarning: true);
      _circuitBreaker.recordFailure();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 5: Bundled Asset Fallback (Emergency)
    // ─────────────────────────────────────────────────────────────────────────
    try {
      developer.log('[DATA SOURCE] Attempting bundled asset fallback: $_fallbackAsset...', name: 'ScientificParser');
      final raw = await rootBundle.loadString(_fallbackAsset).timeout(const Duration(seconds: 10));

      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final (migratedJson, appliedMigrations) = _migrator.migrate(decoded);
      final migratedRaw = jsonEncode(migratedJson);

      final parseOutput = await _verifyAndParse(migratedRaw, profile);

      final List<ReagentTestModel> reagentsList = parseOutput.parsedReagents
          .map((e) => ReagentTestModel.fromJson(e, profile: profile))
          .toList();
      reagentsList.sort((a, b) => a.id.compareTo(b.id));

      _circuitBreaker.reset();
      _currentLifecycleState = DatasetLifecycleState.fallback;
      _cachedReagents = reagentsList;
      _cacheVersion = parseOutput.version;
      _lastDataSource = DataSource.local;

      final metadata = DatasetMetadata(
        source: 'asset',
        author: decoded['author']?.toString() ?? 'System',
        generatedAt: DateTime.tryParse(decoded['generatedAt']?.toString() ?? '') ?? DateTime.now(),
        scientificRevision: decoded['scientificRevision']?.toString() ?? parseOutput.version,
        expiresAt: DateTime.tryParse(decoded['expiresAt']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 365)),
      );

      final lineage = DatasetLineage(
        parentDataset: decoded['version']?.toString() ?? 'unknown',
        migrationsApplied: appliedMigrations,
      );

      final diagnostics = DatasetDiagnostics(
        rawItems: parseOutput.rawItemsCount,
        parsedItems: reagentsList.length,
        skippedItems: parseOutput.skippedItemsCount,
        invalidReferences: parseOutput.invalidReferencesCount,
        invalidColors: parseOutput.invalidColorsCount,
        usedFallback: true,
        datasetVersion: parseOutput.version,
      );

      final snapshot = _makeSnapshot(
        reagents: reagentsList,
        source: DataSource.local,
        health: DataHealthStatus.fallback,
        version: parseOutput.version,
        diagnostics: diagnostics,
        lifecycleState: DatasetLifecycleState.fallback,
        integrity: ScientificIntegrity.fallback,
        warningSeverity: WarningSeverity.critical,
        warningMessage: 'Loaded from bundled asset fallback (Remote Config unavailable).',
        metadata: metadata,
        lineage: lineage,
      );

      _traceLayer('Layer 5 Asset Fallback', snapshot);
      await _atomicWriteCache('scientific_dataset_cache', migratedRaw);
      _snapshotController.add(snapshot);
      stopRecoveryWatchdog();
      _logTelemetry('dataset_load_success', {'source': 'asset_fallback', 'version': parseOutput.version});
      developer.log('[DATA SOURCE] Loaded from bundled asset fallback: ${reagentsList.length} reagents', name: 'ScientificParser');
      return snapshot;
    } catch (e, st) {
      developer.log('[DATA SOURCE] Bundled asset fallback failed, using emergency in-memory dataset', error: e, stackTrace: st, name: 'ScientificParser');
      _logTelemetry('dataset_load_warning', {'error': e.toString(), 'layer': 'asset_fallback'}, isWarning: true);
      _circuitBreaker.recordFailure();
      CrashAnalytics.recordError(e, st, reason: 'Bundled asset fallback load failed');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Layer 6: Emergency In-Memory Fallback Source
    // ─────────────────────────────────────────────────────────────────────────
    developer.log('Running emergency recovery to in-memory dataset', name: 'ScientificParser');
    _currentLifecycleState = DatasetLifecycleState.corrupted;
    _currentWarningSeverity = WarningSeverity.critical;
    _logTelemetry('dataset_load_fatal', {'reason': 'All loading layers failed, falling back to emergency in-memory'}, isFatal: true);
    
    final snapshot = _createFallbackSnapshot(
      source: DataSource.local,
      lifecycleState: DatasetLifecycleState.corrupted,
      integrity: ScientificIntegrity.fallback,
      warningSeverity: WarningSeverity.critical,
      warningMsg: 'Using emergency fallback dataset. Scientific dataset is corrupted or failed to load.',
);

        _traceLayer('Layer 3 Previous Cache', snapshot);
        _snapshotController.add(snapshot);
        startRecoveryWatchdog();
    return snapshot;
  }

  /// Runs JSON parsing in a separate isolate. Falls back to synchronous parsing in tests or on unsupported platforms.
  Future<ParseOutput> _runParse(String rawJson, ValidationProfile profile) async {
    try {
      return await compute(parseScientificDatasetIsolate, ParseParams(rawJson, profile));
    } catch (e, st) {
      developer.log(
        'Isolate parsing not supported or failed. Running synchronously.',
        error: e,
        stackTrace: st,
        name: 'ScientificParser',
      );
      return parseScientificDatasetIsolate(ParseParams(rawJson, profile));
    }
  }

  Future<ParseOutput> _verifyAndParse(String rawJson, ValidationProfile profile) async {
    if (rawJson.length > 5 * 1024 * 1024) {
      throw FormatException('Payload size exceeds budget (5MB limit)');
    }
    final parseOutput = await _runParse(rawJson, profile);
    if (parseOutput.error.isNotEmpty) {
      throw FormatException(parseOutput.error);
    }
    if (parseOutput.parsedReagents.isEmpty) {
      throw FormatException('No valid reagents parsed');
    }
    return parseOutput;
  }

  /// Atomic Cache Write via temporary keys and SHA-256 verification
  Future<bool> _atomicWriteCache(String key, String data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tmpKey = '${key}_tmp';
      final hashKey = '${key}_hash';
      final tmpHashKey = '${key}_hash_tmp';

      final expectedHash = sha256.convert(utf8.encode(data)).toString();

      await prefs.setString(tmpKey, data);
      await prefs.setString(tmpHashKey, expectedHash);

      // Verify write integrity
      final readBackData = prefs.getString(tmpKey);
      if (readBackData == null) return false;
      final readBackHash = sha256.convert(utf8.encode(readBackData)).toString();

      if (readBackHash == expectedHash) {
        await prefs.setString(key, readBackData);
        await prefs.setString(hashKey, expectedHash);
        await prefs.remove(tmpKey);
        await prefs.remove(tmpHashKey);
        return true;
      } else {
        developer.log('❌ Atomic write integrity check failed!', name: 'ScientificParser');
        return false;
      }
    } catch (e) {
      developer.log('❌ Error during atomic cache write: $e', name: 'ScientificParser');
      return false;
    }
  }

  /// Gzip Snapshot helper functions
  String compressGzip(String data) {
    final bytes = utf8.encode(data);
    final compressed = gzip.encode(bytes);
    return base64Encode(compressed);
  }

  String decompressGzip(String compressedBase64) {
    final compressedBytes = base64Decode(compressedBase64);
    final decompressed = gzip.decode(compressedBytes);
    return utf8.decode(decompressed);
  }

  /// Gets all data (uses cache if available)
  Future<DataSnapshot> getAllData() async {
    if (hasCachedData) {
      final diagnostics = DatasetDiagnostics(
        rawItems: _cachedReagents!.length,
        parsedItems: _cachedReagents!.length,
        skippedItems: 0,
        invalidReferences: 0,
        invalidColors: 0,
        usedFallback: _lastDataSource == DataSource.staleCache,
        datasetVersion: _cacheVersion,
      );

      return _makeSnapshot(
        reagents: _cachedReagents!,
        source: _lastDataSource,
        health: _lastDataSource == DataSource.staleCache
            ? DataHealthStatus.fallback
            : DataHealthStatus.healthy,
        version: _cacheVersion,
        diagnostics: diagnostics,
        lifecycleState: _currentLifecycleState,
        integrity: _lastDataSource == DataSource.staleCache
            ? ScientificIntegrity.fallback
            : ScientificIntegrity.verified,
        warningSeverity: _currentWarningSeverity,
      );
    }
    return loadPipeline();
  }

  /// Forces a fresh load from Remote Config
  Future<DataSnapshot> refresh() async {
    developer.log('[DATA SOURCE] Refreshing dataset from Remote Config', name: 'ScientificParser');
    _cachedReagents = null;
    return loadPipeline();
  }

  /// Find a single reagent by name (case-insensitive)
  Future<ReagentTestModel?> getReagentByName(String name) async {
    final snapshot = await getAllData();
    try {
      return snapshot.reagents.firstWhere(
        (r) => r.reagentName.toLowerCase() == name.toLowerCase() ||
               r.reagentNameAr.toLowerCase() == name.toLowerCase() ||
               r.id.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Search reagents by query
  Future<List<ReagentTestModel>> searchReagents(String query) async {
    final snapshot = await getAllData();
    final q = query.toLowerCase();
    return snapshot.reagents.where((r) =>
        r.reagentName.toLowerCase().contains(q) ||
        r.reagentNameAr.contains(q) ||
        r.description.toLowerCase().contains(q) ||
        r.descriptionAr.contains(q) ||
        r.chemicals.any((c) => c.toLowerCase().contains(q))
    ).toList();
  }

  /// Compatibility method for loading safety instructions
  Future<ReagentSafetyData?> getSafetyData(String name) async {
    final reagent = await getReagentByName(name);
    if (reagent == null) return null;
    return ReagentSafetyData(
      reagentName: reagent.reagentName,
      safetyLevel: reagent.safetyLevel,
      requiredEquipment: reagent.safety.requiredEquipment,
      handlingProcedures: reagent.safety.handlingProcedures,
      specificHazards: reagent.safety.specificHazards,
      storageRequirements: reagent.safety.storageRequirements,
    );
  }

  /// Compatibility method for loading references
  Future<List<String>> getReferences(String name) async {
    final reagent = await getReagentByName(name);
    return reagent?.references ?? [];
  }

  /// Watchdog methods
  void startRecoveryWatchdog() {
    if (_recoveryTimer != null) return;
    developer.log('Starting background recovery watchdog...', name: 'RecoveryWatchdog');
    _recoveryTimer = Timer.periodic(recoveryInterval, (timer) async {
      if (_recoveryAttemptsInSession >= maxRecoveryAttemptsPerSession) {
        developer.log('Max recovery attempts ($maxRecoveryAttemptsPerSession) reached. Stopping watchdog.', name: 'RecoveryWatchdog');
        timer.cancel();
        _recoveryTimer = null;
        return;
      }
      
      if (_currentLifecycleState == DatasetLifecycleState.healthy) {
        developer.log('Dataset is healthy. Tearing down recovery watchdog.', name: 'RecoveryWatchdog');
        timer.cancel();
        _recoveryTimer = null;
        return;
      }

      _recoveryAttemptsInSession++;
      developer.log('Recovery attempt $_recoveryAttemptsInSession/$maxRecoveryAttemptsPerSession...', name: 'RecoveryWatchdog');
      
      final prevLifecycleState = _currentLifecycleState;
      _currentLifecycleState = DatasetLifecycleState.recovering;
      
      try {
        final snapshot = await loadPipeline(forceAssetReload: true);
        if (snapshot.lifecycleState == DatasetLifecycleState.healthy) {
          developer.log('Watchdog successfully recovered dataset to healthy state!', name: 'RecoveryWatchdog');
          timer.cancel();
          _recoveryTimer = null;
        } else {
          _currentLifecycleState = snapshot.lifecycleState;
        }
      } catch (e) {
        _currentLifecycleState = prevLifecycleState;
        developer.log('Watchdog recovery attempt failed: $e', name: 'RecoveryWatchdog');
      }
    });
  }

  void stopRecoveryWatchdog() {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
    _recoveryAttemptsInSession = 0;
  }

  // ─── Runtime trace helper ───
  void _traceLayer(String layer, DataSnapshot snapshot) {
    final names = snapshot.reagents.map((r) => r.reagentName).take(8).toList();
    developer.log('[TRACE] $layer emitted: count=${snapshot.reagents.length} first=$names',
        name: 'PipelineTrace');
  }

  void _logTelemetry(String eventName, Map<String, dynamic> metadata, {bool isWarning = false, bool isFatal = false}) {
    if (isWarning) {
      final random = double.parse((DateTime.now().microsecondsSinceEpoch % 100 / 100.0).toStringAsFixed(2));
      if (random > _warningSampleRate) {
        return; // sampled out
      }
    }
    
    final event = DatasetTelemetryEvent(eventName: eventName, metadata: metadata);
    _telemetryBatch.add(event);

    if (_telemetryBatch.length >= _telemetryBatchSize || isFatal) {
      _flushTelemetry();
    }
  }

  void _flushTelemetry() {
    if (_telemetryBatch.isEmpty) return;
    final batchToSend = List<DatasetTelemetryEvent>.from(_telemetryBatch);
    _telemetryBatch.clear();
    developer.log('Uploading deferred telemetry batch of ${batchToSend.length} events.', name: 'ScientificTelemetry');
  }

  void _traceLayer(String layerName, DataSnapshot snapshot) {
    final names = snapshot.reagents.map((r) => r.id).toList();
    final first10 = names.length > 10 ? names.sublist(0, 10) : names;
    final hasMarquis = names.any((n) => n.contains('Marquis'));
    final hasMecke = names.any((n) => n.contains('Mecke'));
    developer.log('[PIPELINE TRACE] $layerName selected | count=${names.length} | first10=$first10 | marquis=$hasMarquis | mecke=$hasMecke', name: 'PipelineTrace');
  }

  DataSnapshot _createFallbackSnapshot({
    required DataSource source,
    required DatasetLifecycleState lifecycleState,
    required ScientificIntegrity integrity,
    required WarningSeverity warningSeverity,
    required String warningMsg,
  }) {
    final reagentsList = _emergencyFallbackReagents;
    _cachedReagents = reagentsList;
    _cacheVersion = 'emergency_1.0.0';
    _lastDataSource = source;

    final diagnostics = DatasetDiagnostics(
      rawItems: reagentsList.length,
      parsedItems: reagentsList.length,
      skippedItems: 0,
      invalidReferences: 0,
      invalidColors: 0,
      usedFallback: true,
      datasetVersion: 'emergency_1.0.0',
    );

    return _makeSnapshot(
      reagents: reagentsList,
      source: source,
      health: DataHealthStatus.corrupted,
      version: 'emergency_1.0.0',
      diagnostics: diagnostics,
      lifecycleState: lifecycleState,
      integrity: integrity,
      warningSeverity: warningSeverity,
      warningMessage: warningMsg,
    );
  }

  void dispose() {
    stopRecoveryWatchdog();
    _snapshotController.close();
  }

  static final List<ReagentTestModel> _emergencyFallbackReagents = [
    ReagentTestModel(
      id: 'marquis_test',
      reagentName: 'Marquis Test',
      reagentNameAr: 'كاشف ماركيز',
      description: 'Primary screening reagent for presumptive identification of laboratory specimens.',
      descriptionAr: 'كاشف الفحص الأساسي لتحديد عينات المختبر المفترضة.',
      safetyLevel: 'HIGH',
      safetyLevelAr: 'مرتفع',
      category: 'Primary',
      testDuration: 15,
      chemicals: const ['Concentrated Sulfuric Acid', 'Formaldehyde'],
      testInstructions: const [
        ReagentTestInstructionStep(step: 1, instruction: 'Place a small specimen amount onto a clean white ceramic plate.', instructionAr: 'ضع كمية صغيرة من العينة على طبق سيراميك أبيض نظيف.'),
        ReagentTestInstructionStep(step: 2, instruction: 'Dispense one drop of Marquis reagent directly onto the specimen.', instructionAr: 'ضع قطرة واحدة من كاشف ماركيز مباشرة على العينة.'),
        ReagentTestInstructionStep(step: 3, instruction: 'Observe color reaction continuously for up to 60 seconds.', instructionAr: 'راقب تفاعل اللون باستمرار لمدة تصل إلى 60 ثانية.'),
      ],
      reactionResults: const [
        DrugResultModel(drugName: 'Opiates', color: 'Purple-Violet', colorAr: 'أرجواني - بنفسجي'),
        DrugResultModel(drugName: 'Amphetamines', color: 'Orange to Brown', colorAr: 'برتقالي إلى بني'),
      ],
      references: const [
        'Auterhoff & Braun, Arch.Pharm. (1973)',
        'Clarkes Analysis of Drugs and Poisons (2011)',
      ],
      safety: const ReagentTestSafetyInfo(
        requiredEquipment: ['Nitrile Gloves', 'Safety Goggles', 'Fume Hood'],
        handlingProcedures: ['Always add acid to water, never water to acid.', 'Keep container tightly closed when not in use.'],
        specificHazards: ['Causes severe skin burns and eye damage.', 'Corrosive to metals.'],
        storageRequirements: ['Store in a cool, well-ventilated place.', 'Keep away from strong bases and organic materials.'],
      ),
    ),
    ReagentTestModel(
      id: 'mecke_test',
      reagentName: 'Mecke Test',
      reagentNameAr: 'كاشف ميكي',
      description: 'Secondary screening reagent containing selenious acid in sulfuric acid.',
      descriptionAr: 'كاشف فحص ثانوي يحتوي على حمض السيلينيوز في حمض الكبريتيك.',
      safetyLevel: 'HIGH',
      safetyLevelAr: 'مرتفع',
      category: 'Secondary',
      testDuration: 15,
      chemicals: const ['Concentrated Sulfuric Acid', 'Selenious Acid'],
      testInstructions: const [
        ReagentTestInstructionStep(step: 1, instruction: 'Place a small specimen amount onto a clean white ceramic plate.', instructionAr: 'ضع كمية صغيرة من العينة على طبق سيراميك أبيض نظيف.'),
        ReagentTestInstructionStep(step: 2, instruction: 'Dispense one drop of Mecke reagent directly onto the specimen.', instructionAr: 'ضع قطرة واحدة من كاشف ميكي مباشرة على العينة.'),
        ReagentTestInstructionStep(step: 3, instruction: 'Observe color reaction for up to 60 seconds.', instructionAr: 'راقب تفاعل اللون لمدة تصل إلى 60 ثانية.'),
      ],
      reactionResults: const [
        DrugResultModel(drugName: 'Opiates', color: 'Blue-Green', colorAr: 'أزرق - أخضر'),
      ],
      references: const [
        'National Institute of Justice Standard 0601.02 (2001)',
      ],
      safety: const ReagentTestSafetyInfo(
        requiredEquipment: ['Nitrile Gloves', 'Safety Goggles', 'Fume Hood'],
        handlingProcedures: ['Handle with extreme caution.', 'Avoid skin and eye contact.'],
        specificHazards: ['Toxic if inhaled or swallowed.', 'Causes severe skin burns.'],
        storageRequirements: ['Store away from combustible materials.', 'Keep container locked up.'],
      ),
    ),
  ];

  // ── Safe Store Mode Snapshot Processor ──────────────────────────────────────

  DataSnapshot _makeSnapshot({
    required List<ReagentTestModel> reagents,
    required DataSource source,
    required DataHealthStatus health,
    required String version,
    required DatasetDiagnostics diagnostics,
    required DatasetLifecycleState lifecycleState,
    required ScientificIntegrity integrity,
    required WarningSeverity warningSeverity,
    String? warningMessage,
    DatasetMetadata? metadata,
    DatasetLineage? lineage,
  }) {
    final processed = _processAndSanitizeReagents(reagents);
    
    final adjustedDiagnostics = DatasetDiagnostics(
      rawItems: processed.length,
      parsedItems: processed.length,
      skippedItems: diagnostics.skippedItems,
      invalidReferences: diagnostics.invalidReferences,
      invalidColors: diagnostics.invalidColors,
      usedFallback: diagnostics.usedFallback,
      datasetVersion: diagnostics.datasetVersion,
    );

    return DataSnapshot(
      reagents: UnmodifiableListView(processed),
      source: source,
      health: health,
      version: version,
      loadedAt: DateTime.now(),
      diagnostics: adjustedDiagnostics,
      lifecycleState: lifecycleState,
      integrity: integrity,
      warningSeverity: warningSeverity,
      warningMessage: warningMessage,
      metadata: metadata,
      lineage: lineage,
    );
  }

  List<ReagentTestModel> _processAndSanitizeReagents(List<ReagentTestModel> originalList) {
    final rc = _remoteConfig;
    final isSafeStore = rc?.safeStoreMode ?? SafeStoreSanitizer.safeStoreMode;
    final isScottEnabled = rc?.enableScottTest ?? true;
    final isHighRiskEnabled = rc?.enableHighRiskTests ?? true;
    final isScientificReferencesEnabled = rc?.enableScientificReferences ?? true;

    // Filter reagents
    List<ReagentTestModel> filtered = originalList.where((reagent) {
      final idLower = reagent.id.toLowerCase();
      
      // 1. Filter out Scott Test if disabled
      if (!isScottEnabled && idLower.contains('scott')) {
        return false;
      }
      
      // 2. Filter out High Risk Tests if disabled
      if (!isHighRiskEnabled) {
        final highRiskKeywords = ['scott', 'heroin', 'morphine', 'codeine', 'simon', 'ehrlich', 'liebermann', 'mandelin'];
        if (highRiskKeywords.any((kw) => idLower.contains(kw))) {
          return false;
        }
      }
      
      return true;
    }).toList();

    // If safe store mode is disabled, we return the filtered list immediately
    if (!isSafeStore) {
      return filtered;
    }

    // Set sanitizer mode dynamically
    SafeStoreSanitizer.safeStoreMode = true;

    // Clone and sanitize visible UI strings
    return filtered.map((reagent) {
      final sanitizedName = SafeStoreSanitizer.sanitize(reagent.reagentName);
      final sanitizedNameAr = SafeStoreSanitizer.sanitize(reagent.reagentNameAr);
      final sanitizedDesc = SafeStoreSanitizer.sanitize(reagent.description);
      final sanitizedDescAr = SafeStoreSanitizer.sanitize(reagent.descriptionAr);
      final sanitizedSafetyLevelAr = SafeStoreSanitizer.sanitize(reagent.safetyLevelAr);

      final sanitizedInstructions = reagent.testInstructions.map((step) {
        return ReagentTestInstructionStep(
          step: step.step,
          instruction: SafeStoreSanitizer.sanitize(step.instruction),
          instructionAr: SafeStoreSanitizer.sanitize(step.instructionAr),
        );
      }).toList();

      List<DrugResultModel> sanitizedReactionResults = reagent.reactionResults;
      sanitizedReactionResults = reagent.reactionResults.map((result) {
        return DrugResultModel(
          drugName: SafeStoreSanitizer.sanitize(result.drugName),
          color: SafeStoreSanitizer.sanitize(result.color),
          colorAr: SafeStoreSanitizer.sanitize(result.colorAr),
        );
      }).toList();

      final sanitizedReferences = isScientificReferencesEnabled 
          ? reagent.references.map((ref) => SafeStoreSanitizer.sanitize(ref)).toList()
          : <String>[];

      // Sanitize chemicals list
      final sanitizedChemicals = reagent.chemicals.map((c) => SafeStoreSanitizer.sanitize(c)).toList();

      // Sanitize ReagentTestSafetyInfo
      final sanitizedSafety = ReagentTestSafetyInfo(
        requiredEquipment: reagent.safety.requiredEquipment.map((s) => SafeStoreSanitizer.sanitize(s)).toList(),
        handlingProcedures: reagent.safety.handlingProcedures.map((s) => SafeStoreSanitizer.sanitize(s)).toList(),
        specificHazards: reagent.safety.specificHazards.map((s) => SafeStoreSanitizer.sanitize(s)).toList(),
        storageRequirements: reagent.safety.storageRequirements.map((s) => SafeStoreSanitizer.sanitize(s)).toList(),
      );

      return ReagentTestModel(
        id: reagent.id,
        reagentName: sanitizedName,
        reagentNameAr: sanitizedNameAr,
        description: sanitizedDesc,
        descriptionAr: sanitizedDescAr,
        safetyLevel: reagent.safetyLevel,
        safetyLevelAr: sanitizedSafetyLevelAr,
        category: reagent.category,
        testDuration: reagent.testDuration,
        chemicals: sanitizedChemicals,
        testInstructions: sanitizedInstructions,
        reactionResults: sanitizedReactionResults,
        references: sanitizedReferences,
        safety: sanitizedSafety,
      );
    }).toList();
  }
}
