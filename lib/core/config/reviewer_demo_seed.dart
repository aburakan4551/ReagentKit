import 'package:reagentkit/features/reagent_testing/domain/entities/test_result_entity.dart';

/// Preloads test results and laboratory logs for Apple reviewer demonstration.
class ReviewerDemoSeed {
  /// Generates a list of realistic, fully populated scientific test logs.
  static List<TestResultEntity> getDemoResults() {
    final now = DateTime.now();
    return [
      TestResultEntity(
        id: 'review_seed_001',
        reagentName: 'Chemical Analysis Kit', // Sanitized Marquis
        testCompletedAt: now.subtract(const Duration(hours: 1, minutes: 20)),
        observedColor: 'Purple',
        possibleSubstances: const ['Analytical Compound A', 'Chemical Compound B'],
        confidencePercentage: 95,
        notes: 'Observed clean reaction on cobalt test kit sample.\n\n'
            'Analytical Observation:\n'
            'Sample reacted within 5 seconds displaying a clear transition to deep purple. '
            'Matches standard reference profile for laboratory validation.\n\n'
            'Safety recommendation: Always handle reagents under ventilated hoods with nitrile gloves.',
      ),
      TestResultEntity(
        id: 'review_seed_002',
        reagentName: 'Organic Analysis Kit', // Sanitized Mecke
        testCompletedAt: now.subtract(const Duration(hours: 5, minutes: 45)),
        observedColor: 'Dark Green',
        possibleSubstances: const ['Organic Element C', 'Marker D'],
        confidencePercentage: 90,
        notes: 'Laboratory educational scan completed with high confidence.\n\n'
            'Analytical Observation:\n'
            'Reaction produced steady color progression to dark green. Stability index: High.\n\n'
            'Safety recommendation: Neutralize with sodium bicarbonate before disposal.',
      ),
      TestResultEntity(
        id: 'review_seed_003',
        reagentName: 'Reagent C', // Sanitized Scott
        testCompletedAt: now.subtract(const Duration(days: 1, hours: 2)),
        observedColor: 'Blue / Cobalt Blue',
        possibleSubstances: const ['Cobalt Precipitate E'],
        confidencePercentage: 88,
        notes: 'Reagent engine evaluation completed.\n\n'
            'Analytical Observation:\n'
            'Cobalt thiocyanate solution formed blue precipitate in the organic layer.\n\n'
            'Safety recommendation: Avoid inhalation of vapour. Keep container locked up.',
      ),
      TestResultEntity(
        id: 'review_seed_004',
        reagentName: 'Analytical Reagent Kit', // Sanitized Simon
        testCompletedAt: now.subtract(const Duration(days: 2, hours: 8)),
        observedColor: 'Deep Blue',
        possibleSubstances: const ['Secondary Amine Complex F'],
        confidencePercentage: 92,
        notes: 'Secondary amine validation check.\n\n'
            'Analytical Observation:\n'
            'Addition of sodium nitroprusside followed by acetaldehyde yielded deep blue color.\n\n'
            'Safety recommendation: Rinse thoroughly with water if contact occurs.',
      ),
    ];
  }
}
