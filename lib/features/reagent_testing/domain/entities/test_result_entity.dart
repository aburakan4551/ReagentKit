class TestResultEntity {
  final String id;
  final String reagentName;
  final String observedColor;
  final List<String> possibleSubstances;
  final int confidencePercentage;
  final String? notes;
  final DateTime testCompletedAt;

  const TestResultEntity({
    required this.id,
    required this.reagentName,
    required this.observedColor,
    required this.possibleSubstances,
    required this.confidencePercentage,
    this.notes,
    required this.testCompletedAt,
  });

  TestResultEntity copyWith({
    String? id,
    String? reagentName,
    String? observedColor,
    List<String>? possibleSubstances,
    int? confidencePercentage,
    String? notes,
    DateTime? testCompletedAt,
  }) {
    return TestResultEntity(
      id: id ?? this.id,
      reagentName: reagentName ?? this.reagentName,
      observedColor: observedColor ?? this.observedColor,
      possibleSubstances: possibleSubstances ?? this.possibleSubstances,
      confidencePercentage: confidencePercentage ?? this.confidencePercentage,
      notes: notes ?? this.notes,
      testCompletedAt: testCompletedAt ?? this.testCompletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reagentName': reagentName,
      'observedColor': observedColor,
      'possibleSubstances': possibleSubstances,
      'confidencePercentage': confidencePercentage,
      'notes': notes,
      'testCompletedAt': testCompletedAt.toIso8601String(),
    };
  }

  factory TestResultEntity.fromJson(Map<String, dynamic> json) {
    return TestResultEntity(
      id: json['id'] as String,
      reagentName: json['reagentName'] as String,
      observedColor: json['observedColor'] as String,
      possibleSubstances: List<String>.from(json['possibleSubstances'] as List),
      confidencePercentage: json['confidencePercentage'] as int,
      notes: json['notes'] as String?,
      testCompletedAt: DateTime.parse(json['testCompletedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestResultEntity &&
        other.id == id &&
        other.reagentName == reagentName &&
        other.observedColor == observedColor &&
        other.possibleSubstances.toString() == possibleSubstances.toString() &&
        other.confidencePercentage == confidencePercentage &&
        other.notes == notes &&
        other.testCompletedAt == testCompletedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      reagentName,
      observedColor,
      possibleSubstances,
      confidencePercentage,
      notes,
      testCompletedAt,
    );
  }
}
