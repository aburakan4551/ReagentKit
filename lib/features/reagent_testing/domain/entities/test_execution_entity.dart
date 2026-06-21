class TestExecutionEntity {
  final String reagentName;
  final DateTime startTime;
  final int timerDuration;
  final String? selectedColor;
  final String? notes;

  const TestExecutionEntity({
    required this.reagentName,
    required this.startTime,
    required this.timerDuration,
    this.selectedColor,
    this.notes,
  });

  TestExecutionEntity copyWith({
    String? reagentName,
    DateTime? startTime,
    int? timerDuration,
    String? selectedColor,
    String? notes,
  }) {
    return TestExecutionEntity(
      reagentName: reagentName ?? this.reagentName,
      startTime: startTime ?? this.startTime,
      timerDuration: timerDuration ?? this.timerDuration,
      selectedColor: selectedColor ?? this.selectedColor,
      notes: notes ?? this.notes,
    );
  }
}
