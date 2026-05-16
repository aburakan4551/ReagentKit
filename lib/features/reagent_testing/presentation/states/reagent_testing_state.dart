import '../../domain/entities/reagent_entity.dart';

abstract class ReagentTestingState {
  const ReagentTestingState();
}

class ReagentTestingInitial extends ReagentTestingState {
  const ReagentTestingInitial();
}

class ReagentTestingLoading extends ReagentTestingState {
  const ReagentTestingLoading();
}

class ReagentTestingLoaded extends ReagentTestingState {
  final List<ReagentEntity> reagents;
  final String? searchQuery;
  final String? selectedSafetyLevel;

  const ReagentTestingLoaded({
    required this.reagents,
    this.searchQuery,
    this.selectedSafetyLevel,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReagentTestingLoaded &&
        _listEquals(other.reagents, reagents) &&
        other.searchQuery == searchQuery &&
        other.selectedSafetyLevel == selectedSafetyLevel;
  }

  @override
  int get hashCode {
    return reagents.hashCode ^
        searchQuery.hashCode ^
        selectedSafetyLevel.hashCode;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class ReagentTestingError extends ReagentTestingState {
  final String message;

  const ReagentTestingError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReagentTestingError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class ReagentTestingEmpty extends ReagentTestingState {
  final String message;

  const ReagentTestingEmpty(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReagentTestingEmpty && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
