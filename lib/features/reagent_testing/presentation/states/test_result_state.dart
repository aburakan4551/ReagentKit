import '../../domain/entities/test_result_entity.dart';

abstract class TestResultState {
  const TestResultState();
}

class TestResultInitial extends TestResultState {
  const TestResultInitial();
}

class TestResultLoading extends TestResultState {
  const TestResultLoading();
}

class TestResultLoaded extends TestResultState {
  final TestResultEntity testResult;

  const TestResultLoaded({required this.testResult});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestResultLoaded && other.testResult == testResult;
  }

  @override
  int get hashCode => testResult.hashCode;
}

class TestResultError extends TestResultState {
  final String message;

  const TestResultError({required this.message});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestResultError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
