import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/test_result_history_repository.dart';
import '../../domain/entities/test_result_entity.dart';
import '../states/test_result_history_state.dart';
import '../../../../core/utils/logger.dart';

class TestResultHistoryController
    extends StateNotifier<TestResultHistoryState> {
  final TestResultHistoryRepository _repository;

  TestResultHistoryController(this._repository)
    : super(const TestResultHistoryInitial());

  // Load all test results
  Future<void> loadTestResults() async {
    state = const TestResultHistoryLoading();

    try {
      final results = await _repository.getAllTestResults();
      state = TestResultHistoryLoaded(results: results);
    } catch (e) {
      state = TestResultHistoryError(message: e.toString());
    }
  }

  // Save a new test result
  Future<void> saveTestResult(TestResultEntity testResult) async {
    try {
      await _repository.saveTestResult(testResult);
      // Reload the results to update the UI
      await loadTestResults();
    } catch (e) {
      state = TestResultHistoryError(message: e.toString());
    }
  }

  // Delete a test result
  Future<void> deleteTestResult(String testResultId) async {
    try {
      await _repository.deleteTestResult(testResultId);
      // Reload the results to update the UI
      await loadTestResults();
    } catch (e) {
      state = TestResultHistoryError(message: e.toString());
    }
  }

  // Clear all test results
  Future<void> clearAllResults() async {
    try {
      await _repository.clearAllTestResults();
      state = const TestResultHistoryLoaded(results: []);
    } catch (e) {
      state = TestResultHistoryError(message: e.toString());
    }
  }

  // Get results by reagent name
  List<TestResultEntity> getResultsByReagent(String reagentName) {
    return state.maybeWhen(
      loaded: (results) =>
          results.where((result) => result.reagentName == reagentName).toList(),
      orElse: () => [],
    );
  }

  // Get results by date range
  List<TestResultEntity> getResultsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return state.maybeWhen(
      loaded: (results) => results
          .where(
            (result) =>
                result.testCompletedAt.isAfter(startDate) &&
                result.testCompletedAt.isBefore(endDate),
          )
          .toList(),
      orElse: () => [],
    );
  }

  // Get statistics
  Map<String, dynamic> getStatistics() {
    return state.maybeWhen(
      loaded: (results) {
        if (results.isEmpty) {
          return {
            'totalTests': 0,
            'mostUsedReagent': 'None',
            'averageConfidence': 0.0,
            'testsByReagent': <String, int>{},
          };
        }

        final testsByReagent = <String, int>{};
        double totalConfidence = 0;

        for (final result in results) {
          testsByReagent[result.reagentName] =
              (testsByReagent[result.reagentName] ?? 0) + 1;
          totalConfidence += result.confidencePercentage;
        }

        final mostUsedReagent = testsByReagent.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        return {
          'totalTests': results.length,
          'mostUsedReagent': mostUsedReagent,
          'averageConfidence': totalConfidence / results.length,
          'testsByReagent': testsByReagent,
        };
      },
      orElse: () => {
        'totalTests': 0,
        'mostUsedReagent': 'None',
        'averageConfidence': 0.0,
        'testsByReagent': <String, int>{},
      },
    );
  }

  // Search results by substance name
  List<TestResultEntity> searchBySubstance(String substanceName) {
    return state.maybeWhen(
      loaded: (results) => results
          .where(
            (result) => result.possibleSubstances.any(
              (substance) =>
                  substance.toLowerCase().contains(substanceName.toLowerCase()),
            ),
          )
          .toList(),
      orElse: () => [],
    );
  }

  // Refresh results
  Future<void> refresh() async {
    await loadTestResults();
  }

  // 🔥 CRITICAL: Clear all data and refresh (for user switching)
  Future<void> clearAndRefresh() async {
    try {
      // Clear all local storage
      await _repository.clearAllLocalStorage();

      // Reset state to initial
      state = const TestResultHistoryInitial();

      // Reload results for current user
      await loadTestResults();

      Logger.info('✅ TestResultHistoryController: Data cleared and refreshed');
    } catch (e) {
      Logger.info(
        '❌ TestResultHistoryController: Failed to clear and refresh: $e',
      );
      state = TestResultHistoryError(message: e.toString());
    }
  }
}
