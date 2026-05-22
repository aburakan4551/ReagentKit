class TestResultEntity {
  final String id;
  final String reagentName;
  final String observedColor;
  final List<String> possibleSubstances;
  final int confidencePercentage;
  final String? notes;
  final DateTime testCompletedAt;
  
  // Scientific Engine Extensions
  final double? colorMatchConfidence;
  final double? aiInterpretationConfidence;
  final double? stabilityIndex;
  final double? deltaE;
  final String? observedHex;
  final String? observedRgb;
  final String? interpretationCategory;
  final String? algorithmVersion;

  const TestResultEntity({
    required this.id,
    required this.reagentName,
    required this.observedColor,
    required this.possibleSubstances,
    required this.confidencePercentage,
    this.notes,
    required this.testCompletedAt,
    this.colorMatchConfidence,
    this.aiInterpretationConfidence,
    this.stabilityIndex,
    this.deltaE,
    this.observedHex,
    this.observedRgb,
    this.interpretationCategory,
    this.algorithmVersion,
  });

  TestResultEntity copyWith({
    String? id,
    String? reagentName,
    String? observedColor,
    List<String>? possibleSubstances,
    int? confidencePercentage,
    String? notes,
    DateTime? testCompletedAt,
    double? colorMatchConfidence,
    double? aiInterpretationConfidence,
    double? stabilityIndex,
    double? deltaE,
    String? observedHex,
    String? observedRgb,
    String? interpretationCategory,
    String? algorithmVersion,
  }) {
    return TestResultEntity(
      id: id ?? this.id,
      reagentName: reagentName ?? this.reagentName,
      observedColor: observedColor ?? this.observedColor,
      possibleSubstances: possibleSubstances ?? this.possibleSubstances,
      confidencePercentage: confidencePercentage ?? this.confidencePercentage,
      notes: notes ?? this.notes,
      testCompletedAt: testCompletedAt ?? this.testCompletedAt,
      colorMatchConfidence: colorMatchConfidence ?? this.colorMatchConfidence,
      aiInterpretationConfidence: aiInterpretationConfidence ?? this.aiInterpretationConfidence,
      stabilityIndex: stabilityIndex ?? this.stabilityIndex,
      deltaE: deltaE ?? this.deltaE,
      observedHex: observedHex ?? this.observedHex,
      observedRgb: observedRgb ?? this.observedRgb,
      interpretationCategory: interpretationCategory ?? this.interpretationCategory,
      algorithmVersion: algorithmVersion ?? this.algorithmVersion,
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
      'colorMatchConfidence': colorMatchConfidence,
      'aiInterpretationConfidence': aiInterpretationConfidence,
      'stabilityIndex': stabilityIndex,
      'deltaE': deltaE,
      'observedHex': observedHex,
      'observedRgb': observedRgb,
      'interpretationCategory': interpretationCategory,
      'algorithmVersion': algorithmVersion,
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
      colorMatchConfidence: (json['colorMatchConfidence'] as num?)?.toDouble(),
      aiInterpretationConfidence: (json['aiInterpretationConfidence'] as num?)?.toDouble(),
      stabilityIndex: (json['stabilityIndex'] as num?)?.toDouble(),
      deltaE: (json['deltaE'] as num?)?.toDouble(),
      observedHex: json['observedHex'] as String?,
      observedRgb: json['observedRgb'] as String?,
      interpretationCategory: json['interpretationCategory'] as String?,
      algorithmVersion: json['algorithmVersion'] as String?,
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
        other.testCompletedAt == testCompletedAt &&
        other.colorMatchConfidence == colorMatchConfidence &&
        other.aiInterpretationConfidence == aiInterpretationConfidence &&
        other.stabilityIndex == stabilityIndex &&
        other.deltaE == deltaE &&
        other.observedHex == observedHex &&
        other.observedRgb == observedRgb &&
        other.interpretationCategory == interpretationCategory &&
        other.algorithmVersion == algorithmVersion;
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
      colorMatchConfidence,
      aiInterpretationConfidence,
      stabilityIndex,
      deltaE,
      observedHex,
      observedRgb,
      interpretationCategory,
      algorithmVersion,
    );
  }
}
