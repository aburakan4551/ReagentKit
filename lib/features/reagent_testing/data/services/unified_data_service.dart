import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:crypto/crypto.dart';
import '../models/reagent_test_model.dart';
import '../../../../core/utils/logger.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Enums & Value Objects
// ═════════════════════════════════════════════════════════════════════════════

enum DataSource { firebase, local, staleCache }

enum DataHealthStatus {
  healthy,
  degraded,
  fallback,
}

// ─── DataSnapshot ────────────────────────────────────────────────────────────

/// Everything the UI needs to know about the current data load result.
class DataSnapshot {
  final List<ReagentTestModel> reagents;
  final DataSource source;
  final DataHealthStatus health;
  final String version;
  final DateTime loadedAt;
  final String? warningMessage;

  const DataSnapshot({
    required this.reagents,
    required this.source,
    required this.health,
    required this.version,
    required this.loadedAt,
    this.warningMessage,
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

// ═════════════════════════════════════════════════════════════════════════════
// UnifiedDataService — Local First & Checked (Production-Grade)
// ═════════════════════════════════════════════════════════════════════════════

class UnifiedDataService {
  // Keep parameters in constructor for backward compatibility
  // ignore: unused_field
  final dynamic _remoteConfig;
  // ignore: unused_field
  final dynamic _connectivity;

  // Cache
  List<ReagentTestModel>? _cachedReagents;
  String _cacheVersion = '1.0.0';
  bool _initialized = false;

  static const String _datasetAsset = 'assets/data/scientific_dataset.json';

  final _snapshotController = StreamController<DataSnapshot>.broadcast();
  Stream<DataSnapshot> get onSnapshot => _snapshotController.stream;

  DataSource get lastSource => _lastDataSource;
  DataSource _lastDataSource = DataSource.local;
  bool get hasCachedData => _cachedReagents != null;
  bool get firebaseEverLoaded => false; // Local-only now
  String get cacheVersion => _cacheVersion;

  UnifiedDataService({
    dynamic remoteConfig,
    dynamic connectivity,
  })  : _remoteConfig = remoteConfig,
        _connectivity = connectivity;

  /// Initialises the dataset and validates integrity in the background
  Future<void> initialize() async {
    if (_initialized) return;
    Logger.info('🚀 [UnifiedDataService] Initializing local scientific dataset...');
    try {
      await loadFromAssets();
      _initialized = true;
      Logger.info('✅ [UnifiedDataService] Initialization complete');
    } catch (e, st) {
      Logger.error('❌ [UnifiedDataService] Initialization failed: $e', error: e, stackTrace: st);
    }
  }

  /// Compatibility method: loads local assets since Remote Config is removed
  Future<DataSnapshot> fetchFromRemoteConfig() async {
    Logger.info('☁️ [UnifiedDataService] Remote config bypass: loading from assets...');
    return loadFromAssets();
  }

  /// Loads, parses, and validates the local JSON dataset
  Future<DataSnapshot> loadFromAssets() async {
    Logger.info('📂 [UnifiedDataService] Loading dataset from $_datasetAsset');
    try {
      final raw = await rootBundle.loadString(_datasetAsset);
      
      // Parse JSON
      final Map<String, dynamic> decoded = json.decode(raw) as Map<String, dynamic>;
      final version = decoded['dataset_version'] as String? ?? '1.0.0';
      final expectedChecksum = decoded['checksum'] as String? ?? '';
      
      // 1. Perform background validation & integrity checks
      _performBackgroundValidation(decoded, raw, expectedChecksum);

      // Parse Reagents
      final reagentsMap = decoded['reagents'] as Map<String, dynamic>? ?? {};
      final List<ReagentTestModel> reagentsList = [];

      reagentsMap.forEach((key, value) {
        try {
          final reagentJson = value as Map<String, dynamic>;
          reagentsList.add(ReagentTestModel.fromJson(reagentJson));
        } catch (e) {
          Logger.error('❌ [UnifiedDataService] Parse error for reagent "$key": $e');
        }
      });

      if (reagentsList.isEmpty) {
        throw const FormatException('Scientific dataset yielded zero valid reagents');
      }

      _cachedReagents = reagentsList;
      _cacheVersion = version;
      _lastDataSource = DataSource.local;

      final snapshot = DataSnapshot(
        reagents: reagentsList,
        source: DataSource.local,
        health: DataHealthStatus.healthy,
        version: version,
        loadedAt: DateTime.now(),
      );

      _snapshotController.add(snapshot);
      return snapshot;
    } catch (e, st) {
      Logger.error('❌ [UnifiedDataService] Local asset load failed: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Gets all data (uses cache if available)
  Future<DataSnapshot> getAllData() async {
    if (hasCachedData) {
      return DataSnapshot(
        reagents: _cachedReagents!,
        source: _lastDataSource,
        health: DataHealthStatus.healthy,
        version: _cacheVersion,
        loadedAt: DateTime.now(),
      );
    }
    return loadFromAssets();
  }

  /// Refreshes the local cache from JSON asset
  Future<DataSnapshot> refresh() async {
    Logger.info('🔄 [UnifiedDataService] Refreshing local dataset');
    _cachedReagents = null;
    return loadFromAssets();
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

  /// Performs background validation and SHA-256 integrity check
  void _performBackgroundValidation(Map<String, dynamic> decoded, String rawText, String expectedChecksum) {
    // Run validation asynchronously to avoid blocking the main thread
    scheduleMicrotask(() {
      Logger.info('🔍 [Dataset Validator] Starting background integrity validation...');
      
      // 1. Verify Checksum
      try {
        if (expectedChecksum.isNotEmpty) {
          // Replace checksum value in raw text to check integrity
          final stripped = rawText.replaceAll(expectedChecksum, "");
          final bytes = utf8.encode(stripped);
          final computedHash = sha256.convert(bytes).toString();
          
          if (computedHash != expectedChecksum) {
            Logger.warning('⚠️ [Dataset Validator] Checksum mismatch! Expected: $expectedChecksum, Computed: $computedHash. Continuing fallback load.');
          } else {
            Logger.info('✅ [Dataset Validator] Checksum verification PASSED');
          }
        }
      } catch (e) {
        Logger.error('❌ [Dataset Validator] Checksum verification failed: $e');
      }

      // 2. Validate Reagents structure and IDs
      try {
        final reagentsMap = decoded['reagents'] as Map<String, dynamic>? ?? {};
        final seenIds = <String>{};
        int duplicateCount = 0;
        int missingIdCount = 0;

        reagentsMap.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final id = value['id'] as String? ?? '';
            final name = value['reagentName'] as String? ?? '';

            if (id.isEmpty) {
              missingIdCount++;
              Logger.warning('⚠️ [Dataset Validator] Reagent under key "$key" is missing a unique "id".');
            } else if (id != key) {
              Logger.warning('⚠️ [Dataset Validator] Reagent "id" ($id) does not match JSON key ($key).');
            }

            if (seenIds.contains(id)) {
              duplicateCount++;
              Logger.warning('⚠️ [Dataset Validator] Duplicate reagent "id" found: "$id".');
            } else if (id.isNotEmpty) {
              seenIds.add(id);
            }

            if (name.isEmpty) {
              Logger.warning('⚠️ [Dataset Validator] Reagent "$id" is missing "reagentName".');
            }
          }
        });

        if (duplicateCount > 0 || missingIdCount > 0) {
          Logger.warning('⚠️ [Dataset Validator] Validation completed with issues: $duplicateCount duplicates, $missingIdCount missing IDs.');
        } else {
          Logger.info('✅ [Dataset Validator] Structure validation PASSED. Checked ${seenIds.length} reagents.');
        }
      } catch (e) {
        Logger.error('❌ [Dataset Validator] Structure validation failed: $e');
      }
    });
  }

  void dispose() {
    _snapshotController.close();
  }
}
