import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/test_result_entity.dart';
import '../../../../core/utils/logger.dart';

class TestResultHistoryRepository {
  static const String _localStorageKey = 'test_result_history';
  static const String _resultHistoryCollection = 'resultHistory';
  static const String _testsSubcollection = 'tests';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user document reference in resultHistory collection
  DocumentReference? get _userDocRef {
    final user = _auth.currentUser;
    if (user?.email == null) return null;
    return _firestore.collection(_resultHistoryCollection).doc(user!.email);
  }

  // Get tests subcollection reference
  CollectionReference? get _testsRef {
    final userDoc = _userDocRef;
    if (userDoc == null) return null;
    return userDoc.collection(_testsSubcollection);
  }

  // Initialize user document if it doesn't exist - COST OPTIMIZED
  Future<void> _initializeUserDocument() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    final userDocRef = _userDocRef!;
    final userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      await userDocRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? 'Anonymous',
        'createdAt': FieldValue.serverTimestamp(),
      });
      Logger.info('✅ User document created for ${user.email}');
    }
  }

  // Generate custom document ID: timestamp_reagentName
  String _generateDocumentId(String reagentName, DateTime timestamp) {
    final timestampStr = timestamp.millisecondsSinceEpoch.toString();
    final cleanReagentName = reagentName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return '${timestampStr}_$cleanReagentName';
  }

  // Save test result to both local storage and Firestore
  Future<void> saveTestResult(TestResultEntity testResult) async {
    try {
      // Always save to local storage first (offline-first approach)
      await _saveToLocalStorage(testResult);

      // Try to save to Firestore if user is authenticated
      final user = _auth.currentUser;
      if (user?.email != null) {
        try {
          await _initializeUserDocument();
          await _saveToFirestore(testResult);
        } catch (firestoreError) {
          // If Firestore fails, log the error but don't throw
          // The result is still saved locally
          Logger.info('Warning: Failed to save to Firestore: $firestoreError');
        }
      }
    } catch (e) {
      throw Exception('Failed to save test result: $e');
    }
  }

  // Get all test results from local storage
  Future<List<TestResultEntity>> getLocalTestResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_localStorageKey);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => TestResultEntity.fromJson(json)).toList()
        ..sort((a, b) => b.testCompletedAt.compareTo(a.testCompletedAt));
    } catch (e) {
      throw Exception('Failed to load local test results: $e');
    }
  }

  // Get test results from Firestore tests subcollection for current user
  Future<List<TestResultEntity>> getFirestoreTestResults() async {
    try {
      final testsRef = _testsRef;
      if (testsRef == null) return [];

      final querySnapshot = await testsRef
          .orderBy('testCompletedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => TestResultEntity.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      Logger.info('Failed to load Firestore test results: $e');
      return [];
    }
  }

  // Get all test results - prioritize Firestore if user is authenticated
  Future<List<TestResultEntity>> getAllTestResults() async {
    try {
      final user = _auth.currentUser;

      // If user is authenticated, show only Firestore results
      if (user?.email != null) {
        Logger.info(
          '🔧 User authenticated (${user!.email}), loading results from Firestore only',
        );
        final firestoreResults = await getFirestoreTestResults();
        Logger.info(
          '🔧 Loaded ${firestoreResults.length} results from Firestore for ${user.email}',
        );
        return firestoreResults;
      } else {
        // If user is not authenticated, show empty results (no local fallback)
        Logger.info('🔧 User not authenticated, returning empty results');
        return [];
      }
    } catch (e) {
      Logger.info('⚠️ Failed to load from Firestore: $e');

      // Check if user is still authenticated
      final user = _auth.currentUser;
      if (user?.email != null) {
        // User is authenticated but Firestore failed - return empty instead of local fallback
        Logger.info(
          '🔧 User authenticated but Firestore failed, returning empty results to prevent data bleeding',
        );
        return [];
      } else {
        // User not authenticated - return empty
        Logger.info(
          '🔧 User not authenticated and Firestore failed, returning empty results',
        );
        return [];
      }
    }
  }

  // Delete a test result from both local and Firestore
  Future<void> deleteTestResult(String testResultId) async {
    try {
      final user = _auth.currentUser;

      if (user?.email != null) {
        // User is authenticated - delete from Firestore only
        final testsRef = _testsRef;
        if (testsRef != null) {
          await testsRef.doc(testResultId).delete();
          Logger.info('✅ Deleted test result from Firestore: $testResultId');
        }
      } else {
        // User not authenticated - delete from local storage
        await _removeFromLocalStorage(testResultId);
        Logger.info('✅ Deleted test result from local storage: $testResultId');
      }
    } catch (e) {
      throw Exception('Failed to delete test result: $e');
    }
  }

  // Clear all test results for current user
  Future<void> clearAllTestResults() async {
    try {
      final user = _auth.currentUser;

      if (user?.email != null) {
        // User is authenticated - clear Firestore only
        final testsRef = _testsRef;
        if (testsRef != null) {
          final querySnapshot = await testsRef.get();

          final batch = _firestore.batch();
          for (final doc in querySnapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          Logger.info('✅ Cleared all test results from Firestore');
        }
      } else {
        // User not authenticated - clear local storage only
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_localStorageKey);
        Logger.info('✅ Cleared all test results from local storage');
      }
    } catch (e) {
      throw Exception('Failed to clear test results: $e');
    }
  }

  // Private method to save to local storage
  Future<void> _saveToLocalStorage(TestResultEntity testResult) async {
    final prefs = await SharedPreferences.getInstance();
    final existingResults = await getLocalTestResults();

    // Remove existing result with same ID if it exists
    existingResults.removeWhere((result) => result.id == testResult.id);

    // Add new result
    existingResults.insert(0, testResult);

    // Keep only last 100 results to prevent storage bloat
    if (existingResults.length > 100) {
      existingResults.removeRange(100, existingResults.length);
    }

    final jsonString = json.encode(
      existingResults.map((result) => result.toJson()).toList(),
    );

    await prefs.setString(_localStorageKey, jsonString);
  }

  // Private method to save to Firestore (tests subcollection structure)
  Future<void> _saveToFirestore(TestResultEntity testResult) async {
    final testsRef = _testsRef;
    if (testsRef == null) return;

    // Generate custom document ID
    final customId = _generateDocumentId(
      testResult.reagentName,
      testResult.testCompletedAt,
    );

    final data = testResult.toJson();
    // Remove the id field as it will be the document ID
    data.remove('id');
    data['createdAt'] = FieldValue.serverTimestamp();

    await testsRef.doc(customId).set(data);
    Logger.info('✅ Test result saved with ID: $customId');
  }

  // Private method to remove from local storage
  Future<void> _removeFromLocalStorage(String testResultId) async {
    final prefs = await SharedPreferences.getInstance();
    final existingResults = await getLocalTestResults();

    existingResults.removeWhere((result) => result.id == testResultId);

    final jsonString = json.encode(
      existingResults.map((result) => result.toJson()).toList(),
    );

    await prefs.setString(_localStorageKey, jsonString);
  }

  // Get test results by reagent name for current user
  Future<List<TestResultEntity>> getTestResultsByReagent(
    String reagentName,
  ) async {
    try {
      final testsRef = _testsRef;
      if (testsRef == null) return [];

      final querySnapshot = await testsRef
          .where('reagentName', isEqualTo: reagentName)
          .orderBy('testCompletedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => TestResultEntity.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      Logger.info('Failed to load test results by reagent: $e');
      return [];
    }
  }

  // Get test results by date range for current user
  Future<List<TestResultEntity>> getTestResultsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final testsRef = _testsRef;
      if (testsRef == null) return [];

      final querySnapshot = await testsRef
          .where(
            'testCompletedAt',
            isGreaterThanOrEqualTo: startDate.toIso8601String(),
          )
          .where(
            'testCompletedAt',
            isLessThanOrEqualTo: endDate.toIso8601String(),
          )
          .orderBy('testCompletedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => TestResultEntity.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      Logger.info('Failed to load test results by date range: $e');
      return [];
    }
  }

  // Cost-optimized incremental sync (Firebase 2025 recommendation)
  Future<void> syncIncrementalToFirestore() async {
    try {
      final testsRef = _testsRef;
      if (testsRef == null) return;

      await _initializeUserDocument();

      // Get last sync timestamp from user preferences
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTimestamp = prefs.getInt('last_firestore_sync') ?? 0;
      final lastSyncDate = DateTime.fromMillisecondsSinceEpoch(
        lastSyncTimestamp,
      );

      // Only get local results created after last sync
      final localResults = await getLocalTestResults();
      final newResults = localResults.where((result) {
        return result.testCompletedAt.isAfter(lastSyncDate);
      }).toList();

      if (newResults.isEmpty) {
        Logger.info('✅ No new results to sync');
        return;
      }

      // Batch write new results only (no read operations needed)
      final batch = _firestore.batch();

      for (final result in newResults) {
        final customId = _generateDocumentId(
          result.reagentName,
          result.testCompletedAt,
        );

        final data = result.toJson();
        data.remove('id');
        data['createdAt'] = FieldValue.serverTimestamp();

        batch.set(testsRef.doc(customId), data);
      }

      await batch.commit();

      // Update last sync timestamp
      await prefs.setInt(
        'last_firestore_sync',
        DateTime.now().millisecondsSinceEpoch,
      );

      Logger.info(
        '✅ Synced ${newResults.length} new results to Firestore (cost-optimized)',
      );
    } catch (e) {
      throw Exception('Failed to sync results to Firestore: $e');
    }
  }

  // 🔥 FIREBASE 2025 COST OPTIMIZATIONS 🔥

  // Cache for expensive queries (reduces repeated reads)
  static final Map<String, List<TestResultEntity>> _queryCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Get cached results if available and not expired
  Future<List<TestResultEntity>> getCachedTestResults() async {
    final user = _auth.currentUser;
    if (user?.email == null) return getLocalTestResults();

    final cacheKey = 'results_${user!.email}';
    final cachedResults = _queryCache[cacheKey];
    final cacheTimestamp = _cacheTimestamps[cacheKey];

    // Return cached results if valid and not expired
    if (cachedResults != null &&
        cacheTimestamp != null &&
        DateTime.now().difference(cacheTimestamp) < _cacheExpiry) {
      Logger.info('Returning cached results (cost: \$0.00)');
      return cachedResults;
    }

    // Cache miss or expired - fetch from Firestore
    final results = await getFirestoreTestResults();

    // Update cache
    _queryCache[cacheKey] = results;
    _cacheTimestamps[cacheKey] = DateTime.now();

    return results;
  }

  // Paginated results (reduces read costs for large datasets)
  Future<List<TestResultEntity>> getTestResultsPaginated({
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      final testsRef = _testsRef;
      if (testsRef == null) return [];

      Query query = testsRef
          .orderBy('testCompletedAt', descending: true)
          .limit(limit);

      // Add pagination cursor if provided
      if (lastDocumentId != null) {
        final lastDoc = await testsRef.doc(lastDocumentId).get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      final querySnapshot = await query.get();

      Logger.info('Paginated query cost: ${querySnapshot.docs.length} reads');

      return querySnapshot.docs
          .map(
            (doc) => TestResultEntity.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      Logger.info('Failed to load paginated results: $e');
      return [];
    }
  }

  // Get only recent results (last 30 days) - reduces read costs
  Future<List<TestResultEntity>> getRecentTestResults() async {
    try {
      final testsRef = _testsRef;
      if (testsRef == null) return [];

      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final querySnapshot = await testsRef
          .where(
            'testCompletedAt',
            isGreaterThanOrEqualTo: thirtyDaysAgo.toIso8601String(),
          )
          .orderBy('testCompletedAt', descending: true)
          .get();

      Logger.info(
        'Recent results query cost: ${querySnapshot.docs.length} reads',
      );

      return querySnapshot.docs
          .map(
            (doc) => TestResultEntity.fromJson({
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            }),
          )
          .toList();
    } catch (e) {
      Logger.info('Failed to load recent results: $e');
      return [];
    }
  }

  // Count documents without reading data (Firebase 2025 feature)
  Future<int> getTestResultsCount() async {
    try {
      final testsRef = _testsRef;
      if (testsRef == null) return 0;

      final countQuery = testsRef.count();
      final snapshot = await countQuery.get();

      Logger.info('🔢 Count query cost: 1 read operation');

      return snapshot.count ?? 0;
    } catch (e) {
      Logger.info('Failed to get results count: $e');
      return 0;
    }
  }

  // Offline-first with smart sync (minimal writes)
  Future<void> saveTestResultOfflineFirst(TestResultEntity testResult) async {
    try {
      // ALWAYS save locally first (cost: $0.00)
      await _saveToLocalStorage(testResult);

      // Queue for background sync instead of immediate Firestore write
      await _queueForBackgroundSync(testResult);

      Logger.info('💾 Saved locally, queued for sync (immediate cost: \$0.00)');
    } catch (e) {
      throw Exception('Failed to save test result offline-first: $e');
    }
  }

  // Background batch sync (reduces write costs)
  Future<void> _queueForBackgroundSync(TestResultEntity testResult) async {
    final prefs = await SharedPreferences.getInstance();
    const queueKey = 'sync_queue';

    final existingQueue = prefs.getStringList(queueKey) ?? [];
    existingQueue.add(json.encode(testResult.toJson()));

    await prefs.setStringList(queueKey, existingQueue);

    // Trigger background sync if queue is large enough
    if (existingQueue.length >= 5) {
      await processSyncQueue();
    }
  }

  // Process sync queue in batches (cost-efficient)
  Future<void> processSyncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const queueKey = 'sync_queue';

      final queuedItems = prefs.getStringList(queueKey) ?? [];
      if (queuedItems.isEmpty) return;

      final testsRef = _testsRef;
      if (testsRef == null) return;

      await _initializeUserDocument();

      // Process in batches of 500 (Firestore limit)
      const batchSize = 500;
      for (int i = 0; i < queuedItems.length; i += batchSize) {
        final batch = _firestore.batch();
        final endIndex = (i + batchSize).clamp(0, queuedItems.length);

        for (int j = i; j < endIndex; j++) {
          final resultJson =
              json.decode(queuedItems[j]) as Map<String, dynamic>;
          final result = TestResultEntity.fromJson(resultJson);

          final customId = _generateDocumentId(
            result.reagentName,
            result.testCompletedAt,
          );

          final data = result.toJson();
          data.remove('id');
          data['createdAt'] = FieldValue.serverTimestamp();

          batch.set(testsRef.doc(customId), data);
        }

        await batch.commit();
        Logger.info(
          '📦 Synced batch ${i ~/ batchSize + 1}: ${endIndex - i} writes',
        );
      }

      // Clear the queue after successful sync
      await prefs.remove(queueKey);

      // Invalidate cache to force refresh
      final user = _auth.currentUser;
      if (user?.email != null) {
        final cacheKey = 'results_${user!.email}';
        _queryCache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
      }

      Logger.info('✅ Processed ${queuedItems.length} queued items');
    } catch (e) {
      Logger.info('Failed to process sync queue: $e');
    }
  }

  // Smart delete with minimal reads
  Future<void> deleteTestResultSmart(String testResultId) async {
    try {
      final user = _auth.currentUser;

      if (user?.email != null) {
        // Direct delete without reading first (cost: 1 delete)
        final testsRef = _testsRef;
        if (testsRef != null) {
          await testsRef.doc(testResultId).delete();

          // Invalidate cache
          final cacheKey = 'results_${user!.email}';
          _queryCache.remove(cacheKey);
          _cacheTimestamps.remove(cacheKey);

          Logger.info('🗑️ Deleted from Firestore (cost: 1 delete)');
        }
      } else {
        // Delete from local storage
        await _removeFromLocalStorage(testResultId);
        Logger.info('🗑️ Deleted from local storage (cost: \$0.00)');
      }
    } catch (e) {
      throw Exception('Failed to delete test result: $e');
    }
  }

  // 🔥 CRITICAL: Clear all local storage (for logout/user switching)
  Future<void> clearAllLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear test results
      await prefs.remove(_localStorageKey);

      // Clear sync queue
      await prefs.remove('sync_queue');

      // Clear last sync timestamp
      await prefs.remove('last_firestore_sync');

      // Clear all query cache
      _queryCache.clear();
      _cacheTimestamps.clear();

      Logger.info('✅ All local storage cleared for user switch/logout');
    } catch (e) {
      Logger.info('❌ Failed to clear local storage: $e');
      throw Exception('Failed to clear local storage: $e');
    }
  }
}
