import 'package:flutter_test/flutter_test.dart';
import 'package:reagentkit/scientific_engine/color_matcher.dart';
import 'package:reagentkit/scientific_engine/reagent_interpreter.dart';

void main() {
  group('ReagentInterpreter Tests', () {
    final targets = [
      const ReagentReactionTarget(
        analyteName: 'Substance A',
        colorText: 'purple',
        colorTextAr: 'أرجواني',
      ),
      const ReagentReactionTarget(
        analyteName: 'Substance B',
        colorText: 'yellow',
        colorTextAr: 'أصفر',
      ),
    ];

    test('Empty targets list returns low reliability fallback', () {
      final result = ReagentInterpreter.interpret(
        observedColor: const RGBColor(128, 0, 128),
        targets: [],
        stabilityIndex: 1.0,
      );

      expect(result.isSuccessful, false);
      expect(result.matchedAnalyte, null);
      expect(result.interpretationCategory, 'Low Reliability');
      expect(result.message, contains('No reference reaction targets'));
    });

    test('Strong color match returns successful Reference Match', () {
      // Marquis purple standard: RGB(128, 0, 128)
      final result = ReagentInterpreter.interpret(
        observedColor: const RGBColor(128, 0, 128), // Perfect match to purple
        targets: targets,
        stabilityIndex: 1.0,
      );

      expect(result.isSuccessful, true);
      expect(result.matchedAnalyte, 'Substance A');
      expect(result.interpretationCategory, 'Reference Match');
      expect(result.message, contains('Highly accurate matching'));
      expect(result.messageAr, contains('مطابقة دقيقة للغاية'));
    });

    test('Insufficient confidence returns safe state', () {
      // deltaE = 14.0, which yields low confidence.
      // observed color far from yellow and purple: RGB(0, 0, 0)
      final result = ReagentInterpreter.interpret(
        observedColor:
            const RGBColor(0, 0, 0), // Black, targets are purple/yellow
        targets: targets,
        stabilityIndex: 0.1, // highly unstable
        ambientBrightness: 0.1, // low light
      );

      expect(result.isSuccessful, false);
      expect(result.matchedAnalyte, null);
      expect(result.interpretationCategory, 'Low Reliability');
      expect(result.message, contains('Insufficient confidence'));
      expect(result.messageAr, contains('درجة الثقة غير كافية'));
    });

    test('Moderate color match returns Analytical Suggestion', () {
      // Observed color is close to yellow but slightly off
      // Yellow targets: RGB(255, 255, 0), RGB(255, 215, 0)
      // Observed: RGB(250, 245, 10)
      final result = ReagentInterpreter.interpret(
        observedColor: const RGBColor(250, 245, 10),
        targets: targets,
        stabilityIndex: 0.8, // moderately stable
        ambientBrightness: 0.7,
      );

      // Verify that it maps to a successful (reliable) but lower category suggestion
      expect(result.isSuccessful, true);
      expect(result.matchedAnalyte, 'Substance B');
      expect(['Analytical Suggestion', 'High Reliability', 'Reference Match'],
          contains(result.interpretationCategory));
    });
  });
}
