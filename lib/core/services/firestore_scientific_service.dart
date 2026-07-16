import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreScientificCacheEntry {
  final String data;
  final DateTime cachedAt;

  const FirestoreScientificCacheEntry({
    required this.data,
    required this.cachedAt,
  });

  Map<String, dynamic> toJson() => {
        'data': data,
        'cachedAt': cachedAt.toIso8601String(),
      };

  factory FirestoreScientificCacheEntry.fromJson(Map<String, dynamic> json) {
    return FirestoreScientificCacheEntry(
      data: json['data'] as String? ?? '',
      cachedAt: DateTime.tryParse(json['cachedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class FirestoreScientificService {
  final FirebaseFirestore _firestore;
  static const Duration _cacheTtl = Duration(hours: 24);

  static const String _reagentsCacheKey = 'firestore_reagents_cache';
  static const String _safetyCacheKey = 'firestore_safety_cache';
  static const String _referencesCacheKey = 'firestore_references_cache';
  static const String _reagentVersionCacheKey =
      'firestore_reagent_version_cache';

  FirestoreScientificService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String?> _getCached(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final entry = FirestoreScientificCacheEntry.fromJson(
          json.decode(raw) as Map<String, dynamic>);
      if (entry.data.isEmpty) return null;
      final age = DateTime.now().difference(entry.cachedAt);
      if (age > _cacheTtl) {
        developer.log(
            '[FirestoreScientific] Cache expired for $key (age: ${age.inHours}h)',
            name: 'FirestoreSci');
        return null;
      }
      developer.log(
          '[FirestoreScientific] Using cached data for $key (age: ${age.inHours}h)',
          name: 'FirestoreSci');
      return entry.data;
    } catch (e) {
      developer.log('[FirestoreScientific] Cache read error for $key: $e',
          name: 'FirestoreSci');
      return null;
    }
  }

  Future<void> _setCached(String key, String data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entry =
          FirestoreScientificCacheEntry(data: data, cachedAt: DateTime.now());
      await prefs.setString(key, json.encode(entry.toJson()));
    } catch (e) {
      developer.log('[FirestoreScientific] Cache write error for $key: $e',
          name: 'FirestoreSci');
    }
  }

  Future<String?> _getStaleCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final entry = FirestoreScientificCacheEntry.fromJson(
          json.decode(raw) as Map<String, dynamic>);
      if (entry.data.isEmpty) return null;
      developer.log('[FirestoreScientific] Using stale cache for $key',
          name: 'FirestoreSci');
      return entry.data;
    } catch (_) {
      return null;
    }
  }

  Future<String> fetchReagentsJson() async {
    final cached = await _getCached(_reagentsCacheKey);
    if (cached != null) return cached;

    try {
      final snapshot = await _firestore.collection('reagents').get();
      if (snapshot.docs.isEmpty) {
        final stale = await _getStaleCache(_reagentsCacheKey);
        if (stale != null) return stale;
        return '{}';
      }

      final Map<String, dynamic> reagentsMap = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['reagentName']?.toString() ?? doc.id;
        reagentsMap[name] = {
          'reagentName': name,
          'reagentName_ar':
              data['reagentName_ar'] ?? data['reagentNameAr'] ?? '',
          'description': data['description'] ?? '',
          'description_ar':
              data['description_ar'] ?? data['descriptionAr'] ?? '',
          'safetyLevel': data['safetyLevel'] ?? 'MEDIUM',
          'safetyLevel_ar':
              data['safetyLevel_ar'] ?? data['safetyLevelAr'] ?? '',
          'testDuration': data['testDuration'] ?? 15,
          'category': data['category'] ?? 'Primary Tests',
          'chemicals': data['chemicals'] is List ? data['chemicals'] : [],
          'reactionResults':
              data['reactionResults'] is List ? data['reactionResults'] : [],
          'testInstructions':
              data['testInstructions'] is List ? data['testInstructions'] : [],
          'reference': data['reference'] is List
              ? data['reference']
              : (data['references'] is List ? data['references'] : []),
          'requiredEquipment': data['requiredEquipment'] is List
              ? data['requiredEquipment']
              : [],
          'handlingProcedures': data['handlingProcedures'] is List
              ? data['handlingProcedures']
              : [],
          'specificHazards':
              data['specificHazards'] is List ? data['specificHazards'] : [],
          'storageRequirements': data['storageRequirements'] is List
              ? data['storageRequirements']
              : [],
        };
      }

      final jsonStr = json.encode({
        'dataset_version': _getReagentVersionFromSnapshot(snapshot),
        'reagents': reagentsMap,
      });

      await _setCached(_reagentsCacheKey, jsonStr);
      developer.log(
          '[FirestoreScientific] Fetched ${reagentsMap.length} reagents from Firestore',
          name: 'FirestoreSci');
      return jsonStr;
    } catch (e) {
      developer.log('[FirestoreScientific] Firestore reagents fetch failed: $e',
          name: 'FirestoreSci');
      final stale = await _getStaleCache(_reagentsCacheKey);
      if (stale != null) return stale;
      return '{}';
    }
  }

  String _getReagentVersionFromSnapshot(QuerySnapshot snapshot) {
    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data() as Map<String, dynamic>?;
      if (data != null) {
        final version = data['dataset_version']?.toString();
        if (version != null && version.isNotEmpty) return version;
      }
    }
    return '1.0.0';
  }

  Future<String> fetchSafetyJson() async {
    final cached = await _getCached(_safetyCacheKey);
    if (cached != null) return cached;

    try {
      final snapshot = await _firestore.collection('safety_notes').get();
      if (snapshot.docs.isEmpty) {
        final stale = await _getStaleCache(_safetyCacheKey);
        if (stale != null) return stale;
        return '{}';
      }

      final Map<String, dynamic> safetyMap = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['reagentName']?.toString() ?? doc.id;
        safetyMap[name] = {
          'reagentName': name,
          'requiredEquipment': data['requiredEquipment'] is List
              ? data['requiredEquipment']
              : [],
          'handlingProcedures': data['handlingProcedures'] is List
              ? data['handlingProcedures']
              : [],
          'specificHazards':
              data['specificHazards'] is List ? data['specificHazards'] : [],
          'storageRequirements': data['storageRequirements'] is List
              ? data['storageRequirements']
              : (data['storage'] is List ? data['storage'] : []),
        };
      }

      final jsonStr = json.encode(safetyMap);
      await _setCached(_safetyCacheKey, jsonStr);
      developer.log(
          '[FirestoreScientific] Fetched ${safetyMap.length} safety notes from Firestore',
          name: 'FirestoreSci');
      return jsonStr;
    } catch (e) {
      developer.log('[FirestoreScientific] Firestore safety fetch failed: $e',
          name: 'FirestoreSci');
      final stale = await _getStaleCache(_safetyCacheKey);
      if (stale != null) return stale;
      return '{}';
    }
  }

  Future<String> fetchReferencesJson() async {
    final cached = await _getCached(_referencesCacheKey);
    if (cached != null) return cached;

    try {
      final snapshot =
          await _firestore.collection('scientific_references').get();
      if (snapshot.docs.isEmpty) {
        final stale = await _getStaleCache(_referencesCacheKey);
        if (stale != null) return stale;
        return '{}';
      }

      final Map<String, dynamic> refsMap = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final substanceName = data['substanceName']?.toString() ?? doc.id;
        final references = data['references'] is List ? data['references'] : [];
        refsMap[substanceName] = {
          'reference': references,
        };
      }

      final jsonStr = json.encode(refsMap);
      await _setCached(_referencesCacheKey, jsonStr);
      developer.log(
          '[FirestoreScientific] Fetched ${refsMap.length} reference entries from Firestore',
          name: 'FirestoreSci');
      return jsonStr;
    } catch (e) {
      developer.log(
          '[FirestoreScientific] Firestore references fetch failed: $e',
          name: 'FirestoreSci');
      final stale = await _getStaleCache(_referencesCacheKey);
      if (stale != null) return stale;
      return '{}';
    }
  }

  Future<String> fetchReagentVersion() async {
    final cached = await _getCached(_reagentVersionCacheKey);
    if (cached != null) return cached;

    try {
      final doc =
          await _firestore.collection('reagent_metadata').doc('version').get();
      if (doc.exists) {
        final data = doc.data();
        final version = data?['version']?.toString() ?? '1.0.0';
        await _setCached(_reagentVersionCacheKey, version);
        developer.log('[FirestoreScientific] Fetched reagent version: $version',
            name: 'FirestoreSci');
        return version;
      }
    } catch (e) {
      developer.log('[FirestoreScientific] Firestore version fetch failed: $e',
          name: 'FirestoreSci');
    }

    final stale = await _getStaleCache(_reagentVersionCacheKey);
    if (stale != null) return stale;
    return '1.0.0';
  }

  Future<bool> hasAnyReagentData() async {
    try {
      final snapshot = await _firestore.collection('reagents').limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_reagentsCacheKey);
      await prefs.remove(_safetyCacheKey);
      await prefs.remove(_referencesCacheKey);
      await prefs.remove(_reagentVersionCacheKey);
      developer.log('[FirestoreScientific] Cache cleared',
          name: 'FirestoreSci');
    } catch (e) {
      developer.log('[FirestoreScientific] Cache clear error: $e',
          name: 'FirestoreSci');
    }
  }

  Future<void> prefetchAll() async {
    try {
      await Future.wait([
        fetchReagentsJson(),
        fetchSafetyJson(),
        fetchReferencesJson(),
        fetchReagentVersion(),
      ]);
      developer.log(
          '[FirestoreScientific] All scientific data prefetched from Firestore',
          name: 'FirestoreSci');
    } catch (e) {
      developer.log('[FirestoreScientific] Prefetch failed (non-fatal): $e',
          name: 'FirestoreSci');
    }
  }

  Stream<void> onReagentsUpdated() {
    return _firestore.collection('reagents').snapshots().map((_) {
      clearCache();
    });
  }

  Stream<void> onSafetyUpdated() {
    return _firestore.collection('safety_notes').snapshots().map((_) {
      clearCache();
    });
  }

  Stream<void> onReferencesUpdated() {
    return _firestore.collection('scientific_references').snapshots().map((_) {
      clearCache();
    });
  }
}
