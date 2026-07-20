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
      cachedAt: DateTime.tryParse(json['cachedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class FirestoreScientificService {
  final FirebaseFirestore _firestore;
  static const Duration _cacheTtl = Duration(hours: 24);

  // Cache keys for all 10 scientific collections
  static const String _reagentsCacheKey = 'firestore_reagents_cache';
  static const String _reagentGroupsCacheKey = 'firestore_reagent_groups_cache';
  static const String _substancesCacheKey = 'firestore_substances_cache';
  static const String _reactionResultsCacheKey = 'firestore_reaction_results_cache';
  static const String _colorProfilesCacheKey = 'firestore_color_profiles_cache';
  static const String _scientificReferencesCacheKey = 'firestore_scientific_references_cache';
  static const String _referenceImagesCacheKey = 'firestore_reference_images_cache';
  static const String _hazardInformationCacheKey = 'firestore_hazard_information_cache';
  static const String _safetyNotesCacheKey = 'firestore_safety_notes_cache';
  static const String _reagentMetadataCacheKey = 'firestore_reagent_metadata_cache';

  FirestoreScientificService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String?> _getCached(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final entry = FirestoreScientificCacheEntry.fromJson(json.decode(raw) as Map<String, dynamic>);
      if (entry.data.isEmpty) return null;
      final age = DateTime.now().difference(entry.cachedAt);
      if (age > _cacheTtl) {
        developer.log('[FirestoreScientific] Cache expired for $key (age: ${age.inHours}h)', name: 'FirestoreSci');
        return null;
      }
      developer.log('[FirestoreScientific] Using cached data for $key (age: ${age.inHours}h)', name: 'FirestoreSci');
      return entry.data;
    } catch (e) {
      developer.log('[FirestoreScientific] Cache read error for $key: $e', name: 'FirestoreSci');
      return null;
    }
  }

  Future<void> _setCached(String key, String data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entry = FirestoreScientificCacheEntry(data: data, cachedAt: DateTime.now());
      await prefs.setString(key, json.encode(entry.toJson()));
    } catch (e) {
      developer.log('[FirestoreScientific] Cache write error for $key: $e', name: 'FirestoreSci');
    }
  }

  Future<String?> _getStaleCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return null;
      final entry = FirestoreScientificCacheEntry.fromJson(json.decode(raw) as Map<String, dynamic>);
      if (entry.data.isEmpty) return null;
      developer.log('[FirestoreScientific] Using stale cache for $key', name: 'FirestoreSci');
      return entry.data;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. Reagents
  // ─────────────────────────────────────────────────────────────────────────────
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
          'reagentName_ar': data['reagentName_ar'] ?? data['reagentNameAr'] ?? '',
          'description': data['description'] ?? '',
          'description_ar': data['description_ar'] ?? data['descriptionAr'] ?? '',
          'safetyLevel': data['safetyLevel'] ?? 'MEDIUM',
          'safetyLevel_ar': data['safetyLevel_ar'] ?? data['safetyLevelAr'] ?? '',
          'testDuration': data['testDuration'] ?? 15,
          'category': data['category'] ?? 'Primary Tests',
          'chemicals': data['chemicals'] is List ? data['chemicals'] : [],
          'reactionResults': data['reactionResults'] is List ? data['reactionResults'] : [],
          'testInstructions': data['testInstructions'] is List ? data['testInstructions'] : [],
          'reference': data['reference'] is List ? data['reference'] : (data['references'] is List ? data['references'] : []),
          'requiredEquipment': data['requiredEquipment'] is List ? data['requiredEquipment'] : [],
          'handlingProcedures': data['handlingProcedures'] is List ? data['handlingProcedures'] : [],
          'specificHazards': data['specificHazards'] is List ? data['specificHazards'] : [],
          'storageRequirements': data['storageRequirements'] is List ? data['storageRequirements'] : [],
        };
      }

      final jsonStr = json.encode({
        'dataset_version': _getReagentVersionFromSnapshot(snapshot),
        'reagents': reagentsMap,
      });

      await _setCached(_reagentsCacheKey, jsonStr);
      developer.log('[FirestoreScientific] Fetched ${reagentsMap.length} reagents from Firestore', name: 'FirestoreSci');
      return jsonStr;
    } catch (e) {
      developer.log('[FirestoreScientific] Firestore reagents fetch failed: $e', name: 'FirestoreSci');
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

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. Reagent Groups
  // ─────────────────────────────────────────────────────────────────────────────
  Future<String> fetchReagentGroupsJson() async {
    final cached = await _getCached(_reagentGroupsCacheKey);
    if (cached != null) return cached;

    try {
      final snapshot = await _firestore.collection('reagent_groups').get();
      if (snapshot.docs.isEmpty) {
        final stale = await _getStaleCache(_reagentGroupsCacheKey);
        if (stale != null) return stale;
        return '{}';
      }

      final Map<String, dynamic> groupsMap = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['groupName']?.toString() ?? doc.id;
        groupsMap[name] = {
          'groupName': name,
          'groupName_ar': data['groupName_ar'] ?? '',
          'description': data['description'] ?? '',
          'description_ar': data['description_ar'] ?? '',
          'reagents': data['reagents'] is List ? data['reagents'] : [],
          'order': data['order'] ?? 0,
        };
      }

      final jsonStr = json.encode(groupsMap);
      await _setCached(_reagentGroupsCacheKey, jsonStr);
      developer.log('[FirestoreScientific] Fetched ${groupsMap.length} reagent groups from Firestore', name: 'FirestoreSci');
      return jsonStr;
    } catch (e) {
      developer.log('[FirestoreScientific] Firestore reagent_groups fetch failed: $e', name: 'FirestoreSci');
      final stale = await _getStaleCache(_reagentGroupsCacheKey);
      if (stale != null) return stale;
      return '{}';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. Substances
  // ─────────────────────────────────────────────────────────────────────────────
  Future<String> fetchSubstancesJson() async {
    final cached = await _getCached(_substancesCacheKey);
    if (cached != null) return cached;

    try {
      final snapshot = await _firestore.collection('substances').get();
      if (snapshot.docs.isEmpty) {
        final stale = await _getStaleCache(_substancesCacheKey);
        if (stale != null) return stale;
        return '{}';
      }

      final Map<String, dynamic> substancesMap = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['substanceName']?.toString() ?? doc.id;
        substancesMap[name] = {
          'substanceName': name,
          'substanceName_ar': data['substanceName_ar'] ?? '',
          'chemicalFormula': data['chemicalFormula'] ?? '',
          'casNumber': data['casNumber'] ?? '',
          'description': data['description'] ?? '',
          'description_ar': data['description_ar'] ?? '',
          'legalStatus': data['legalStatus'] ?? 'UNKNOWN',
          'category': data['category'] ?? 'Other',
        };
      }

      final jsonStr = json.encode(substancesMap);
      await _setCached(_substancesCacheKey, jsonStr);
      developer.log('[FirestoreScientific] Fetched ${substancesMap.length} substances from Firestore', name: 'FirestoreSci');
      return jsonStr;
    } catch (e) {
      developer.log('[FirestoreScientific] Firestore substances fetch failed: $e', name: 'FirestoreSci');
      final stale = await _getStaleCache(_substancesCacheKey);
      if (stale != null) return stale;
      return '{}';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. Reaction Results
  // ─────────────────────────────────────────────────────────────────────────────
  Future<String> fetchReactionResultsJson() async {
    final cached = await _getCached(_reactionResultsCacheKey);
    if (cached != null) return cached;

    try {
      final snapshot = await _firestore.collection('reaction_results').get();
      if (snapshot.docs.isEmpty) {
        final stale = await _getStaleCache(_reactionResultsCacheKey);
        if (stale != null) return stale;
        return '{}';
      }

      final Map<String, dynamic> resultsMap = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final reagentName = data['reagentName']?.toString() ?? '';
        final substanceName = data['substanceName']?.toString() ?? '';
        final key = '$reagentName|$substanceName';
        resultsMap[key] = {
          'reagentName': reagentName,
          'substanceName': substanceName,
          'color': data['color'] ?? '',
          'colorHex': data['colorHex'] ?? '',
          'intensity': data['intensity'] ?? 'MODERATE',
          'reactionTime': data['reactionTime'] ?? 30,
          'notes': data['notes'] ?? '',
        };
      }

      final jsonStr = json.encode(resultsMap);
      await _setCached(_reactionResultsCacheKey, jsonStr);
      developer.log('[FirestoreScientific] Fetched ${resultsMap.length} reaction results from Firestore', name: 'FirestoreSci');
      return jsonStr;
    } catch (e) {
      developer.log('[FirestoreScientific] Firestore reaction_results fetch failed: $e', name: 'FirestoreSci');
      final stale = await _getStaleCache(_reactionResultsCacheKey);
      if (stale != null) return stale;
      return '{}';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. Color Profiles
  // ─────────────────────────────────────────────────────────────────────────────
  Future<String> fetchColorProfilesJson() async {
    final cached = await _getCached(_colorProfilesCacheKey);
    if (cached != null) return cached;

    try {
      final snapshot = await _firestore.collection('color_profiles').get();
      if (snapshot.docs.isEmpty) {
        final stale = await _getStaleCache(_colorProfilesCacheKey);
        if (stale != null) return stale;
        return '{}';
      }

      final Map<String, dynamic> profilesMap = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['profileName']?.toString() ?? doc.id;
        profilesMap[name] = {
          'profileName': name,
          'colors': data['colors'] is List ? data['colors'] : [],
          'tolerances': data['tolerances'] is List ? data['tolerances'] : [],
        };
      }

      final jsonStr = json.encode(profilesMap);
      await _setCached(_colorProfilesCacheKey, jsonStr);
      developer.log('[FirestoreScientific] Fetched ${profilesMap.length} color profiles from Firestore', name: 'FirestoreSci');
      return jsonStr;
    } catch (e) {
      developer.log('[FirestoreScientific] Firestore color_profiles fetch failed: $e', name: 'FirestoreSci');
      final stale = await _getStaleCache(_colorProfilesCacheKey);
      if (stale != null) return stale;
      return '{}';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. Scientific References
  // ─────────────────────────────────────────────────────────────────────────────
  Future<String> fetchReferencesJson() async {
    final cached = await _getCached(_scientificReferencesCacheKey);
    if (cached != null) return cached;

    try {
      final snapshot = await _firestore.collection('scientific_references').get();
      if (snapshot.docs.isEmpty) {
        final stale = await _getStaleCache(_scientificReferencesCacheKey);
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
      await _setCached(_scientificReferencesCacheKey, jsonStr);
      developer.log('[FirestoreScientific] Fetched ${refsMap.length} reference entries from Firestore', name: 'FirestoreSci');
      return jsonStr;
    } catch (e) {
      developer.log('[FirestoreScientific] Firestore references fetch failed: $e', name: 'FirestoreSci');
      final stale = await _getStaleCache(_scientificReferencesCacheKey);
      if (stale != null) return stale;
      return '{}';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. Reference Images
  // ─────────────────────────────────────────────────────────────────────────────
  Future<String> fetchReferenceImagesJson() async {
    final cached = await _getCached(_referenceImagesCacheKey);
    if (cached != null) return cached;

    try {
      final snapshot = await _firestore.collection('reference_images').get();
      if (snapshot.docs.isEmpty) {
        final stale = await _getStaleCache(_referenceImagesCacheKey);
        if (stale != null) return stale;
        return '{}';
      }

      final Map<String, dynamic> imagesMap = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final key = data['imageKey']?.toString() ?? doc.id;
        imagesMap[key] = {
          'imageKey': key,
          'reagentName': data['reagentName'] ?? '',
          'substanceName': data['substanceName'] ?? '',
          'imageUrl': data['imageUrl'] ?? '',
          'thumbnailUrl': data['thumbnailUrl'] ?? '',
          'description': data['description'] ?? '',
        };
      }

      final jsonStr = json.encode(imagesMap);
      await _setCached(_referenceImagesCacheKey, jsonStr);
      developer.log('[FirestoreScientific] Fetched ${imagesMap.length} reference images from Firestore', name: 'FirestoreSci');
      return jsonStr;
    } catch (e) {
      developer.log('[FirestoreScientific] Firestore reference_images fetch failed: $e', name: 'FirestoreSci');
      final stale = await _getStaleCache(_referenceImagesCacheKey);
      if (stale != null) return stale;
      return '{}';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 8. Hazard Information
  // ─────────────────────────────────────────────────────────────────────────────
  Future<String> fetchHazardInformationJson() async {
    final cached = await _getCached(_hazardInformationCacheKey);
    if (cached != null) return cached;

    try {
      final snapshot = await _firestore.collection('hazard_information').get();
      if (snapshot.docs.isEmpty) {
        final stale = await _getStaleCache(_hazardInformationCacheKey);
        if (stale != null) return stale;
        return '{}';
      }

      final Map<String, dynamic> hazardsMap = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final substanceName = data['substanceName']?.toString() ?? doc.id;
        hazardsMap[substanceName] = {
          'substanceName': substanceName,
          'ghsPictograms': data['ghsPictograms'] is List ? data['ghsPictograms'] : [],
          'hStatements': data['hStatements'] is List ? data['hStatements'] : [],
          'pStatements': data['pStatements'] is List ? data['pStatements'] : [],
          'signalWord': data['signalWord'] ?? '',
          'hazardClass': data['hazardClass'] ?? '',
        };
      }

      final jsonStr = json.encode(hazardsMap);
      await _setCached(_hazardInformationCacheKey, jsonStr);
      developer.log('[FirestoreScientific] Fetched ${hazardsMap.length} hazard entries from Firestore', name: 'FirestoreSci');
      return jsonStr;
    } catch (e) {
      developer.log('[FirestoreScientific] Firestore hazard_information fetch failed: $e', name: 'FirestoreSci');
      final stale = await _getStaleCache(_hazardInformationCacheKey);
      if (stale != null) return stale;
      return '{}';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 9. Safety Notes
  // ─────────────────────────────────────────────────────────────────────────────
  Future<String> fetchSafetyJson() async {
    final cached = await _getCached(_safetyNotesCacheKey);
    if (cached != null) return cached;

    try {
      final snapshot = await _firestore.collection('safety_notes').get();
      if (snapshot.docs.isEmpty) {
        final stale = await _getStaleCache(_safetyNotesCacheKey);
        if (stale != null) return stale;
        return '{}';
      }

      final Map<String, dynamic> safetyMap = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['reagentName']?.toString() ?? doc.id;
        safetyMap[name] = {
          'reagentName': name,
          'requiredEquipment': data['requiredEquipment'] is List ? data['requiredEquipment'] : [],
          'handlingProcedures': data['handlingProcedures'] is List ? data['handlingProcedures'] : [],
          'specificHazards': data['specificHazards'] is List ? data['specificHazards'] : [],
          'storageRequirements': data['storageRequirements'] is List ? data['storageRequirements'] : (data['storage'] is List ? data['storage'] : []),
        };
      }

      final jsonStr = json.encode(safetyMap);
      await _setCached(_safetyNotesCacheKey, jsonStr);
      developer.log('[FirestoreScientific] Fetched ${safetyMap.length} safety notes from Firestore', name: 'FirestoreSci');
      return jsonStr;
    } catch (e) {
      developer.log('[FirestoreScientific] Firestore safety fetch failed: $e', name: 'FirestoreSci');
      final stale = await _getStaleCache(_safetyNotesCacheKey);
      if (stale != null) return stale;
      return '{}';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 10. Reagent Metadata
  // ─────────────────────────────────────────────────────────────────────────────
  Future<String> fetchReagentVersion() async {
    final cached = await _getCached(_reagentMetadataCacheKey);
    if (cached != null) return cached;

    try {
      final doc = await _firestore.collection('reagent_metadata').doc('version').get();
      if (doc.exists) {
        final data = doc.data();
        final version = data?['version']?.toString() ?? '1.0.0';
        await _setCached(_reagentMetadataCacheKey, version);
        developer.log('[FirestoreScientific] Fetched reagent version: $version', name: 'FirestoreSci');
        return version;
      }
    } catch (e) {
      developer.log('[FirestoreScientific] Firestore version fetch failed: $e', name: 'FirestoreSci');
    }

    final stale = await _getStaleCache(_reagentMetadataCacheKey);
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
      await prefs.remove(_reagentGroupsCacheKey);
      await prefs.remove(_substancesCacheKey);
      await prefs.remove(_reactionResultsCacheKey);
      await prefs.remove(_colorProfilesCacheKey);
      await prefs.remove(_scientificReferencesCacheKey);
      await prefs.remove(_referenceImagesCacheKey);
      await prefs.remove(_hazardInformationCacheKey);
      await prefs.remove(_safetyNotesCacheKey);
      await prefs.remove(_reagentMetadataCacheKey);
      developer.log('[FirestoreScientific] Cache cleared', name: 'FirestoreSci');
    } catch (e) {
      developer.log('[FirestoreScientific] Cache clear error: $e', name: 'FirestoreSci');
    }
  }

  Future<void> prefetchAll() async {
    try {
      await Future.wait([
        fetchReagentsJson(),
        fetchReagentGroupsJson(),
        fetchSubstancesJson(),
        fetchReactionResultsJson(),
        fetchColorProfilesJson(),
        fetchReferencesJson(),
        fetchReferenceImagesJson(),
        fetchHazardInformationJson(),
        fetchSafetyJson(),
        fetchReagentVersion(),
      ]);
      developer.log('[FirestoreScientific] All scientific data prefetched from Firestore', name: 'FirestoreSci');
    } catch (e) {
      developer.log('[FirestoreScientific] Prefetch failed (non-fatal): $e', name: 'FirestoreSci');
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