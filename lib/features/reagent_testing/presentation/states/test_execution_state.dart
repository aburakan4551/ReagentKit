import '../../domain/entities/test_execution_entity.dart';
import '../../data/models/gemini_analysis_models.dart';

abstract class TestExecutionState {
  const TestExecutionState();

  // Add when method for pattern matching
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(
      TestExecutionEntity testExecution,
      GeminiReagentTestResult? aiAnalysisResult,
      String notes,
    )
    loaded,
    required T Function(String message) error,
  }) {
    if (this is TestExecutionInitial) {
      return initial();
    } else if (this is TestExecutionLoading) {
      return loading();
    } else if (this is TestExecutionLoaded) {
      final state = this as TestExecutionLoaded;
      return loaded(state.testExecution, state.aiAnalysisResult, state.notes);
    } else if (this is TestExecutionError) {
      return error((this as TestExecutionError).message);
    }
    throw Exception('Unknown state: $this');
  }

  // Add maybeWhen method for optional pattern matching
  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(
      TestExecutionEntity testExecution,
      GeminiReagentTestResult? aiAnalysisResult,
      String notes,
    )?
    loaded,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    if (this is TestExecutionInitial && initial != null) {
      return initial();
    } else if (this is TestExecutionLoading && loading != null) {
      return loading();
    } else if (this is TestExecutionLoaded && loaded != null) {
      final state = this as TestExecutionLoaded;
      return loaded(state.testExecution, state.aiAnalysisResult, state.notes);
    } else if (this is TestExecutionError && error != null) {
      return error((this as TestExecutionError).message);
    }
    return orElse();
  }
}

class TestExecutionInitial extends TestExecutionState {
  const TestExecutionInitial();
}

class TestExecutionLoading extends TestExecutionState {
  const TestExecutionLoading();
}

class TestExecutionLoaded extends TestExecutionState {
  final TestExecutionEntity testExecution;
  final GeminiReagentTestResult? aiAnalysisResult;
  final String notes;

  const TestExecutionLoaded({
    required this.testExecution,
    this.aiAnalysisResult,
    this.notes = '',
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestExecutionLoaded && other.testExecution == testExecution;
  }

  @override
  int get hashCode => testExecution.hashCode;
}

class TestExecutionError extends TestExecutionState {
  final String message;

  const TestExecutionError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestExecutionError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
