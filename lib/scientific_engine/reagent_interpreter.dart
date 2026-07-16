import 'color_matcher.dart';
import 'confidence_calculator.dart';
import 'scientific_constants.dart';

class ReagentReactionTarget {
  final String analyteName;
  final String colorText;
  final String colorTextAr;

  const ReagentReactionTarget({
    required this.analyteName,
    required this.colorText,
    required this.colorTextAr,
  });
}

class InterpretationResult {
  final String? matchedAnalyte;
  final String? matchedColorText;
  final String? matchedColorTextAr;
  final double deltaE;
  final ConfidenceResult confidence;
  final String
      interpretationCategory; // Preliminary Observation, Analytical Suggestion, Reference Match, Low Reliability, High Reliability
  final String message;
  final String messageAr;

  const InterpretationResult({
    this.matchedAnalyte,
    this.matchedColorText,
    this.matchedColorTextAr,
    required this.deltaE,
    required this.confidence,
    required this.interpretationCategory,
    required this.message,
    required this.messageAr,
  });

  bool get isSuccessful => matchedAnalyte != null && confidence.isReliable;
}

class ReagentInterpreter {
  /// Interprets a reagent test color against a list of possible targets
  static InterpretationResult interpret({
    required RGBColor observedColor,
    required List<ReagentReactionTarget> targets,
    required double stabilityIndex,
    double? customAiConfidence,
    double ambientBrightness = 0.8,
    double cameraExposure = 0.5,
  }) {
    if (targets.isEmpty) {
      return InterpretationResult(
        deltaE: 99.0,
        confidence: const ConfidenceResult(
          colorMatchConfidence: 0.0,
          aiInterpretationConfidence: 0.0,
          stabilityIndex: 0.0,
          overallConfidence: 0.0,
          confidenceRating: 'Low',
          isReliable: false,
        ),
        interpretationCategory: 'Low Reliability',
        message: 'No reference reaction targets available.',
        messageAr: 'لا توجد أهداف تفاعل مرجعية متاحة.',
      );
    }

    double bestDeltaE = double.infinity;
    ReagentReactionTarget? bestTarget;

    // Find the target with the minimum Delta E
    for (final target in targets) {
      final delta = ColorMatcher.getMinDeltaE(observedColor, target.colorText);
      if (delta < bestDeltaE) {
        bestDeltaE = delta;
        bestTarget = target;
      }
    }

    // Calculate confidence for this match
    final conf = ConfidenceCalculator.calculateConfidence(
      deltaE: bestDeltaE,
      stabilityIndex: stabilityIndex,
      customAiConfidence: customAiConfidence,
      ambientBrightness: ambientBrightness,
      cameraExposure: cameraExposure,
    );

    // If confidence is insufficient, return safe state (Apple / Legal Compliance)
    if (!conf.isReliable) {
      return InterpretationResult(
        deltaE: bestDeltaE,
        confidence: conf,
        interpretationCategory: 'Low Reliability',
        message:
            'Insufficient confidence for reliable interpretation. Please calibrate lighting.',
        messageAr: 'درجة الثقة غير كافية لتفسير موثوق. يرجى معايرة الإضاءة.',
      );
    }

    // Determine category based on confidence rating and delta E
    String category;
    String msg;
    String msgAr;

    if (bestDeltaE <= ScientificConstants.deltaEPerfect) {
      category = 'Reference Match';
      msg = 'Highly accurate matching with reference standards.';
      msgAr = 'مطابقة دقيقة للغاية مع المعايير المرجعية.';
    } else if (conf.overallConfidence >=
        ScientificConstants.confidenceThresholdHigh) {
      category = 'High Reliability';
      msg = 'Significant response matching with strong confidence.';
      msgAr = 'مطابقة استجابة دالة بثقة قوية.';
    } else if (conf.overallConfidence >=
        ScientificConstants.confidenceThresholdModerate) {
      category = 'Analytical Suggestion';
      msg = 'Moderate response match suggesting possible presence.';
      msgAr = 'مطابقة استجابة متوسطة تشير إلى احتمالية الوجود.';
    } else {
      category = 'Preliminary Observation';
      msg =
          'Preliminary color response observation with low-level correlation.';
      msgAr = 'ملاحظة لونية أولية مع ارتباط منخفض المستوى.';
    }

    return InterpretationResult(
      matchedAnalyte: bestTarget!.analyteName,
      matchedColorText: bestTarget.colorText,
      matchedColorTextAr: bestTarget.colorTextAr,
      deltaE: bestDeltaE,
      confidence: conf,
      interpretationCategory: category,
      message: msg,
      messageAr: msgAr,
    );
  }
}
