import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/test_result_entity.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/globals.dart';
import '../../../../core/config/reviewer_demo_seed.dart';

class TestResultHistoryRepository {
  static const String _localStorageKey = 'test_result_history';

  // Save test result to local storage
  Future<void> saveTestResult(TestResultEntity testResult) async {
    try {
      await _saveToLocalStorage(testResult);
    } catch (e) {
      throw Exception('Failed to save test result: $e');
    }
  }

  // Get all test results from local storage
  Future<List<TestResultEntity>> getLocalTestResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_localStorageKey);

      if (jsonString == null) {
        if (isPremiumReviewMode) {
          return ReviewerDemoSeed.getDemoResults();
        }
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      final list = jsonList.map((json) => TestResultEntity.fromJson(json)).toList();
      if (list.isEmpty && isPremiumReviewMode) {
        return ReviewerDemoSeed.getDemoResults();
      }
      return list..sort((a, b) => b.testCompletedAt.compareTo(a.testCompletedAt));
    } catch (e) {
      if (isPremiumReviewMode) {
        return ReviewerDemoSeed.getDemoResults();
      }
      throw Exception('Failed to load local test results: $e');
    }
  }

  // Get all test results (local-only after authentication removal)
  Future<List<TestResultEntity>> getAllTestResults() async {
    if (isPremiumReviewMode) {
      final local = await getLocalTestResults();
      if (local.isEmpty) {
        return ReviewerDemoSeed.getDemoResults();
      }
      return local;
    }
    return getLocalTestResults();
  }

  // Delete a test result from local storage
  Future<void> deleteTestResult(String testResultId) async {
    try {
      await _removeFromLocalStorage(testResultId);
      Logger.info('✅ Deleted test result from local storage: $testResultId');
    } catch (e) {
      throw Exception('Failed to delete test result: $e');
    }
  }

  // Clear all test results
  Future<void> clearAllTestResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localStorageKey);
      Logger.info('✅ Cleared all test results from local storage');
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

  // Get test results by reagent name
  Future<List<TestResultEntity>> getTestResultsByReagent(
    String reagentName,
  ) async {
    try {
      final allResults = await getLocalTestResults();
      return allResults
          .where((result) => result.reagentName == reagentName)
          .toList()
        ..sort((a, b) => b.testCompletedAt.compareTo(a.testCompletedAt));
    } catch (e) {
      Logger.info('Failed to load test results by reagent: $e');
      return [];
    }
  }

  // Get test results by date range
  Future<List<TestResultEntity>> getTestResultsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final allResults = await getLocalTestResults();
      return allResults
          .where((result) =>
              !result.testCompletedAt.isBefore(startDate) &&
              !result.testCompletedAt.isAfter(endDate))
          .toList()
        ..sort((a, b) => b.testCompletedAt.compareTo(a.testCompletedAt));
    } catch (e) {
      Logger.info('Failed to load test results by date range: $e');
      return [];
    }
  }

  // Get recent results (last 30 days)
  Future<List<TestResultEntity>> getRecentTestResults() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final allResults = await getLocalTestResults();
      return allResults
          .where((result) => result.testCompletedAt.isAfter(thirtyDaysAgo))
          .toList()
        ..sort((a, b) => b.testCompletedAt.compareTo(a.testCompletedAt));
    } catch (e) {
      Logger.info('Failed to load recent results: $e');
      return [];
    }
  }

  // Get total count of test results
  Future<int> getTestResultsCount() async {
    try {
      final allResults = await getLocalTestResults();
      return allResults.length;
    } catch (e) {
      Logger.info('Failed to get results count: $e');
      return 0;
    }
  }

  // Offline-first save (kept for API compatibility)
  Future<void> saveTestResultOfflineFirst(TestResultEntity testResult) async {
    await _saveToLocalStorage(testResult);
    Logger.info('💾 Saved locally (cost: \$0.00)');
  }

  // Clear all local storage (for app reset)
  Future<void> clearAllLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear test results
      await prefs.remove(_localStorageKey);

      // Clear sync queue
      await prefs.remove('sync_queue');

      // Clear last sync timestamp
      await prefs.remove('last_firestore_sync');

      Logger.info('✅ All local storage cleared');
    } catch (e) {
      Logger.info('❌ Failed to clear local storage: $e');
      throw Exception('Failed to clear local storage: $e');
    }
  }
}
