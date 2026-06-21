import 'package:flutter_test/flutter_test.dart';
import 'package:reagentkit/scientific_engine/confidence_calculator.dart';
import 'package:reagentkit/scientific_engine/scientific_constants.dart';

void main() {
  group('ConfidenceCalculator Color Match Tests', () {
    test('Perfect Delta E returns 1.0 confidence', () {
      final conf = ConfidenceCalculator.calculateColorMatchConfidence(ScientificConstants.deltaEPerfect);
      expect(conf, 1.0);
    });

    test('Zero Delta E returns 1.0 confidence', () {
      final conf = ConfidenceCalculator.calculateColorMatchConfidence(0.0);
      expect(conf, 1.0);
    });

    test('Delta E at or above Max Limit returns 0.0 confidence', () {
      final confAtLimit = ConfidenceCalculator.calculateColorMatchConfidence(ScientificConstants.deltaEMaxLimit);
      final confAboveLimit = ConfidenceCalculator.calculateColorMatchConfidence(ScientificConstants.deltaEMaxLimit + 5.0);
      expect(confAtLimit, 0.0);
      expect(confAboveLimit, 0.0);
    });

    test('Delta E interpolates correctly between perfect and max limit', () {
      // Perfect = 2.0, Max = 15.0. Midpoint = 8.5
      // Expected midpoint confidence = 0.5
      final conf = ConfidenceCalculator.calculateColorMatchConfidence(8.5);
      expect(conf, closeTo(0.5, 0.01));
    });
  });

  group('ConfidenceCalculator Overall Confidence Tests', () {
    test('Calculates High confidence with perfect environment and stable result', () {
      // deltaE = 0.0 -> colorMatchConf = 1.0
      // stabilityIndex = 1.0
      // customAiConfidence = 1.0
      // environment (brightness=0.8, exposure=0.5) -> envMultiplier = 1.0
      // overall = (1.0*0.4) + (1.0*0.3) + (1.0*0.2) + (1.0*0.1) = 1.0
      final result = ConfidenceCalculator.calculateConfidence(
        deltaE: 0.0,
        stabilityIndex: 1.0,
        customAiConfidence: 1.0,
      );

      expect(result.overallConfidence, closeTo(1.0, 0.0001));
      expect(result.confidenceRating, 'High');
      expect(result.isReliable, true);
    });

    test('Degrades overall confidence with low stability', () {
      final result = ConfidenceCalculator.calculateConfidence(
        deltaE: 0.0,
        stabilityIndex: 0.2, // very unstable
        customAiConfidence: 1.0,
      );

      // overall = (1.0*0.4) + (0.2*0.3) + (1.0*0.2) + (1.0*0.1) = 0.4 + 0.06 + 0.2 + 0.1 = 0.76
      // rating should be Moderate (0.75 <= 0.76 < 0.90)
      expect(result.overallConfidence, closeTo(0.76, 0.01));
      expect(result.confidenceRating, 'Moderate');
      expect(result.isReliable, true);
    });

    test('Degrades overall confidence under low light (brightness penalty)', () {
      final result = ConfidenceCalculator.calculateConfidence(
        deltaE: 0.0,
        stabilityIndex: 1.0,
        customAiConfidence: 1.0,
        ambientBrightness: 0.1, // deficit = 0.3 - 0.1 = 0.2. envMultiplier = 1.0 - (0.2/0.3)*0.4 = 1.0 - 0.266 = 0.733
      );

      // envMultiplier = 0.733
      // overall = 0.4 + 0.3 + 0.2 + 0.0733 = 0.9733 (capped at 1.0, wait, no, 0.973)
      expect(result.overallConfidence, closeTo(0.973, 0.01));
    });

    test('Degrades overall confidence under extreme overexposure', () {
      final result = ConfidenceCalculator.calculateConfidence(
        deltaE: 0.0,
        stabilityIndex: 1.0,
        customAiConfidence: 1.0,
        cameraExposure: 0.95, // excess = 0.95 - 0.8 = 0.15. Range = 0.2. envMultiplier = 1 - (0.15/0.2)*0.3 = 0.775
      );

      // envMultiplier = 0.775
      // overall = 0.4 + 0.3 + 0.2 + 0.0775 = 0.9775
      expect(result.overallConfidence, closeTo(0.9775, 0.01));
    });

    test('Classifies Low confidence and marks unreliable when overall falls below threshold', () {
      // deltaE = 14.0 -> colorMatchConf = (15 - 14)/13 = 0.0769
      // stabilityIndex = 0.1
      // customAiConfidence = 0.1
      // brightness = 0.0 (extreme dark) -> envMultiplier = 0.2 (min cap)
      final result = ConfidenceCalculator.calculateConfidence(
        deltaE: 14.0,
        stabilityIndex: 0.1,
        customAiConfidence: 0.1,
        ambientBrightness: 0.0,
      );

      // overall = (0.0769 * 0.4) + (0.1 * 0.3) + (0.1 * 0.2) + (0.2 * 0.1)
      //         = 0.0307 + 0.03 + 0.02 + 0.02 = 0.1007
      expect(result.overallConfidence, lessThan(ScientificConstants.confidenceThresholdLow));
      expect(result.confidenceRating, 'Low');
      expect(result.isReliable, false);
    });

    test('ConfidenceResult toString prints readable information', () {
      final result = ConfidenceCalculator.calculateConfidence(
        deltaE: 2.0,
        stabilityIndex: 1.0,
        customAiConfidence: 0.9,
      );
      
      final str = result.toString();
      expect(str, contains('ColorMatch: 100.0%'));
      expect(str, contains('AI: 90.0%'));
      expect(str, contains('Stability: 100.0%'));
      expect(str, contains('Rating: High'));
    });
  });
}
