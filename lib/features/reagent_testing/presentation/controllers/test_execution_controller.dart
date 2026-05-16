import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/reagent_entity.dart';
import '../../domain/entities/test_execution_entity.dart';
import '../states/test_execution_state.dart';
import '../../data/models/gemini_analysis_models.dart';

class TestExecutionController extends StateNotifier<TestExecutionState> {
  TestExecutionController() : super(const TestExecutionInitial());

  void initializeTest(ReagentEntity reagent) {
    final testExecution = TestExecutionEntity(
      reagentName: reagent.reagentName,
      startTime: DateTime.now(),
      timerDuration: reagent.testDuration * 60, // Convert minutes to seconds
    );

    state = TestExecutionLoaded(testExecution: testExecution);
  }

  void selectColor(String color) {
    if (state is TestExecutionLoaded) {
      final currentState = state as TestExecutionLoaded;
      final updatedExecution = currentState.testExecution.copyWith(
        selectedColor: color,
      );
      state = TestExecutionLoaded(testExecution: updatedExecution);
    }
  }

  void updateAIAnalysisResult(GeminiReagentTestResult? aiResult) {
    state = state.maybeWhen(
      loaded: (testExecution, currentAiResult, notes) => TestExecutionLoaded(
        testExecution: testExecution,
        aiAnalysisResult: aiResult,
        notes: notes,
      ),
      orElse: () => state,
    );
  }

  void updateNotes(String notes) {
    state = state.maybeWhen(
      loaded: (testExecution, aiResult, currentNotes) => TestExecutionLoaded(
        testExecution: testExecution,
        aiAnalysisResult: aiResult,
        notes: notes,
      ),
      orElse: () => state,
    );
  }
}
