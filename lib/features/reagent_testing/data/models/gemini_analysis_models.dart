// Gemini AI Analysis Models

class GeminiChemicalAnalysis {
  final List<String> detectedChemicals;
  final String confidenceLevel;
  final String analysisNotes;
  final List<String> suggestedReagents;
  final String colorAnalysis;

  const GeminiChemicalAnalysis({
    required this.detectedChemicals,
    required this.confidenceLevel,
    required this.analysisNotes,
    required this.suggestedReagents,
    required this.colorAnalysis,
  });

  factory GeminiChemicalAnalysis.fromJson(Map<String, dynamic> json) {
    return GeminiChemicalAnalysis(
      detectedChemicals: List<String>.from(json['detected_chemicals'] ?? []),
      confidenceLevel: json['confidence_level'] ?? '',
      analysisNotes: json['analysis_notes'] ?? '',
      suggestedReagents: List<String>.from(json['suggested_reagents'] ?? []),
      colorAnalysis: json['color_analysis'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'detected_chemicals': detectedChemicals,
      'confidence_level': confidenceLevel,
      'analysis_notes': analysisNotes,
      'suggested_reagents': suggestedReagents,
      'color_analysis': colorAnalysis,
    };
  }
}

class GeminiReagentTestResult {
  final String observedColorDescription;
  final List<String> identifiedSubstances;
  final String primarySubstance;
  final String confidenceLevel;
  final String colorMatchReasoning;
  final String concentrationEstimate;
  final String testResult;
  final String analysisNotes;
  final String recommendations;

  const GeminiReagentTestResult({
    required this.observedColorDescription,
    required this.identifiedSubstances,
    required this.primarySubstance,
    required this.confidenceLevel,
    required this.colorMatchReasoning,
    required this.concentrationEstimate,
    required this.testResult,
    required this.analysisNotes,
    required this.recommendations,
  });

  factory GeminiReagentTestResult.fromJson(Map<String, dynamic> json) {
    return GeminiReagentTestResult(
      observedColorDescription: json['observed_color_description'] ?? '',
      identifiedSubstances: List<String>.from(
        json['identified_substances'] ?? [],
      ),
      primarySubstance: json['primary_substance'] ?? '',
      confidenceLevel: json['confidence_level'] ?? '',
      colorMatchReasoning: json['color_match_reasoning'] ?? '',
      concentrationEstimate: json['concentration_estimate'] ?? '',
      testResult: json['test_result'] ?? '',
      analysisNotes: json['analysis_notes'] ?? '',
      recommendations: json['recommendations'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'observed_color_description': observedColorDescription,
      'identified_substances': identifiedSubstances,
      'primary_substance': primarySubstance,
      'confidence_level': confidenceLevel,
      'color_match_reasoning': colorMatchReasoning,
      'concentration_estimate': concentrationEstimate,
      'test_result': testResult,
      'analysis_notes': analysisNotes,
      'recommendations': recommendations,
    };
  }
}

class ImageAnalysisResult {
  final String imagePath;
  final DateTime timestamp;
  final GeminiChemicalAnalysis? chemicalAnalysis;
  final GeminiReagentTestResult? reagentTestResult;
  final String? errorMessage;

  const ImageAnalysisResult({
    required this.imagePath,
    required this.timestamp,
    this.chemicalAnalysis,
    this.reagentTestResult,
    this.errorMessage,
  });

  factory ImageAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ImageAnalysisResult(
      imagePath: json['imagePath'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      chemicalAnalysis: json['chemicalAnalysis'] != null
          ? GeminiChemicalAnalysis.fromJson(json['chemicalAnalysis'])
          : null,
      reagentTestResult: json['reagentTestResult'] != null
          ? GeminiReagentTestResult.fromJson(json['reagentTestResult'])
          : null,
      errorMessage: json['errorMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
      'chemicalAnalysis': chemicalAnalysis?.toJson(),
      'reagentTestResult': reagentTestResult?.toJson(),
      'errorMessage': errorMessage,
    };
  }
}
