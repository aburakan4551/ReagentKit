import '../../domain/entities/test_result_entity.dart';

abstract class TestResultHistoryState {
  const TestResultHistoryState();

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(List<TestResultEntity> results) loaded,
    required T Function(String message) error,
  }) {
    if (this is TestResultHistoryInitial) {
      return initial();
    } else if (this is TestResultHistoryLoading) {
      return loading();
    } else if (this is TestResultHistoryLoaded) {
      return loaded((this as TestResultHistoryLoaded).results);
    } else if (this is TestResultHistoryError) {
      return error((this as TestResultHistoryError).message);
    }
    throw Exception('Unknown state: $this');
  }

  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(List<TestResultEntity> results)? loaded,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    if (this is TestResultHistoryInitial && initial != null) {
      return initial();
    } else if (this is TestResultHistoryLoading && loading != null) {
      return loading();
    } else if (this is TestResultHistoryLoaded && loaded != null) {
      return loaded((this as TestResultHistoryLoaded).results);
    } else if (this is TestResultHistoryError && error != null) {
      return error((this as TestResultHistoryError).message);
    }
    return orElse();
  }
}

class TestResultHistoryInitial extends TestResultHistoryState {
  const TestResultHistoryInitial();
}

class TestResultHistoryLoading extends TestResultHistoryState {
  const TestResultHistoryLoading();
}

class TestResultHistoryLoaded extends TestResultHistoryState {
  final List<TestResultEntity> results;

  const TestResultHistoryLoaded({required this.results});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestResultHistoryLoaded &&
        other.results.toString() == results.toString();
  }

  @override
  int get hashCode => results.hashCode;
}

class TestResultHistoryError extends TestResultHistoryState {
  final String message;

  const TestResultHistoryError({required this.message});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestResultHistoryError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
