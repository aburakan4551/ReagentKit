import 'dart:math';
import 'scientific_constants.dart';

class ConfidenceResult {
  final double colorMatchConfidence;
  final double aiInterpretationConfidence;
  final double stabilityIndex; // 0.0 to 1.0 (1.0 is perfectly stable)
  final double overallConfidence;
  final String confidenceRating; // Low, Moderate, High
  final bool isReliable;

  const ConfidenceResult({
    required this.colorMatchConfidence,
    required this.aiInterpretationConfidence,
    required this.stabilityIndex,
    required this.overallConfidence,
    required this.confidenceRating,
    required this.isReliable,
  });

  @override
  String toString() {
    return 'ConfidenceResult(ColorMatch: ${(colorMatchConfidence * 100).toStringAsFixed(1)}%, '
        'AI: ${(aiInterpretationConfidence * 100).toStringAsFixed(1)}%, '
        'Stability: ${(stabilityIndex * 100).toStringAsFixed(1)}%, '
        'Rating: $confidenceRating)';
  }
}

class ConfidenceCalculator {
  /// Calculates color match confidence based on Delta E distance
  static double calculateColorMatchConfidence(double deltaE) {
    if (deltaE <= ScientificConstants.deltaEPerfect) {
      return 1.0;
    }
    if (deltaE >= ScientificConstants.deltaEMaxLimit) {
      return 0.0;
    }
    // Interpolate between perfect match and max limit
    final range =
        ScientificConstants.deltaEMaxLimit - ScientificConstants.deltaEPerfect;
    final diff = deltaE - ScientificConstants.deltaEPerfect;
    return max(0.0, min(1.0, 1.0 - (diff / range)));
  }

  /// Calculates overall confidence and returns a detailed [ConfidenceResult]
  static ConfidenceResult calculateConfidence({
    required double deltaE,
    required double stabilityIndex,
    double? customAiConfidence,
    double ambientBrightness = 0.8,
    double cameraExposure = 0.5,
  }) {
    // 1. Calculate color match confidence
    final colorMatchConf = calculateColorMatchConfidence(deltaE);

    // 2. Determine AI Interpretation confidence (fallback to color match if null)
    final aiConf = customAiConfidence ?? max(0.0, colorMatchConf - 0.05);

    // 3. Environmental multiplier based on lighting
    double envMultiplier = 1.0;
    if (ambientBrightness < ScientificConstants.minAmbientBrightness) {
      // Degrade confidence due to low light
      final deficit =
          ScientificConstants.minAmbientBrightness - ambientBrightness;
      envMultiplier -=
          (deficit / ScientificConstants.minAmbientBrightness) * 0.4;
    }
    if (cameraExposure > ScientificConstants.maxCameraExposure) {
      // Degrade confidence due to overexposure
      final excess = cameraExposure - ScientificConstants.maxCameraExposure;
      final range = 1.0 - ScientificConstants.maxCameraExposure;
      envMultiplier -= (excess / range) * 0.3;
    }
    envMultiplier = max(0.2, min(1.0, envMultiplier));

    // 4. Calculate overall confidence: weighted average
    // Weights: color match (40%), stability (30%), AI (20%), environment (10%)
    double overall = (colorMatchConf * 0.4) +
        (stabilityIndex * 0.3) +
        (aiConf * 0.2) +
        (envMultiplier * 0.1);

    overall = max(0.0, min(1.0, overall));

    // 5. Determine Rating
    String rating;
    if (overall >= ScientificConstants.confidenceThresholdHigh) {
      rating = 'High';
    } else if (overall >= ScientificConstants.confidenceThresholdModerate) {
      rating = 'Moderate';
    } else {
      rating = 'Low';
    }

    final isReliable = overall >= ScientificConstants.confidenceThresholdLow;

    return ConfidenceResult(
      colorMatchConfidence: colorMatchConf,
      aiInterpretationConfidence: aiConf,
      stabilityIndex: stabilityIndex,
      overallConfidence: overall,
      confidenceRating: rating,
      isReliable: isReliable,
    );
  }
}
