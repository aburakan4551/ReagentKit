import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/reagent_entity.dart';
import '../../domain/entities/test_result_entity.dart';
import '../states/test_result_state.dart';
import 'test_result_history_controller.dart';
import '../../data/models/gemini_analysis_models.dart';
import '../../../../core/utils/logger.dart';

class TestResultController extends StateNotifier<TestResultState> {
  final TestResultHistoryController? _historyController;

  TestResultController({TestResultHistoryController? historyController})
    : _historyController = historyController,
      super(const TestResultInitial());

  void analyzeTestResult({
    required ReagentEntity reagent,
    required String observedColor,
    String? notes,
  }) {
    state = const TestResultLoading();

    try {
      // Analyze the observed color against the reagent's drug results
      final analysisResult = _analyzeColorMatch(reagent, observedColor);

      final testResult = TestResultEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        reagentName: reagent.reagentName,
        observedColor: observedColor,
        possibleSubstances: analysisResult['substances'] as List<String>,
        confidencePercentage: analysisResult['confidence'] as int,
        notes: notes,
        testCompletedAt: DateTime.now(),
      );

      state = TestResultLoaded(testResult: testResult);

      // Save to history if history controller is available
      _historyController?.saveTestResult(testResult);
    } catch (e) {
      state = TestResultError(message: 'Failed to analyze test result: $e');
    }
  }

  void analyzeTestResultWithAI({
    required ReagentEntity reagent,
    required GeminiReagentTestResult aiResult,
    String? notes,
  }) {
    state = const TestResultLoading();

    try {
      // Debug logging
      Logger.info('🤖 AI Test Result Analysis:');
      Logger.info('  - Observed Color: ${aiResult.observedColorDescription}');
      Logger.info('  - Primary Substance: ${aiResult.primarySubstance}');
      Logger.info(
        '  - Identified Substances: ${aiResult.identifiedSubstances}',
      );
      Logger.info('  - Confidence Level: ${aiResult.confidenceLevel}');
      Logger.info(
        '  - Notes: ${notes?.substring(0, notes.length.clamp(0, 100))}...',
      );

      // Convert AI confidence level to percentage
      int confidencePercentage;
      switch (aiResult.confidenceLevel.toLowerCase()) {
        case 'high':
        case 'very high':
          confidencePercentage = 90;
          break;
        case 'medium':
        case 'moderate':
          confidencePercentage = 70;
          break;
        case 'low':
          confidencePercentage = 50;
          break;
        default:
          confidencePercentage = 60;
      }

      // Use AI-identified substances, or fall back to "AI Analysis" if empty
      final possibleSubstances = aiResult.identifiedSubstances.isNotEmpty
          ? aiResult.identifiedSubstances
          : [
              aiResult.primarySubstance.isNotEmpty
                  ? aiResult.primarySubstance
                  : 'AI Analysis Result',
            ];

      Logger.info('  - Final Possible Substances: $possibleSubstances');
      Logger.info('  - Final Confidence: $confidencePercentage%');

      final testResult = TestResultEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        reagentName: reagent.reagentName,
        observedColor: aiResult.observedColorDescription,
        possibleSubstances: possibleSubstances,
        confidencePercentage: confidencePercentage,
        notes: notes,
        testCompletedAt: DateTime.now(),
      );

      state = TestResultLoaded(testResult: testResult);

      // Save to history if history controller is available
      _historyController?.saveTestResult(testResult);
    } catch (e) {
      state = TestResultError(message: 'Failed to analyze AI test result: $e');
    }
  }

  Map<String, dynamic> _analyzeColorMatch(
    ReagentEntity reagent,
    String observedColor,
  ) {
    final List<String> possibleSubstances = [];
    int confidence = 0;

    // Normalize the observed color for comparison
    final normalizedObservedColor = _normalizeColor(observedColor);

    Logger.info('🎨 Color Matching Analysis:');
    Logger.info('  - Reagent: ${reagent.reagentName}');
    Logger.info('  - Observed Color: "$observedColor"');
    Logger.info('  - Normalized Observed: "$normalizedObservedColor"');

    // Check each drug result for color matches
    for (final drugResult in reagent.drugResults) {
      final expectedColors = _extractColorsFromDescription(drugResult.color);

      Logger.info('  - Checking ${drugResult.drugName}: "${drugResult.color}"');
      Logger.info('    - Extracted colors: $expectedColors');

      for (final expectedColor in expectedColors) {
        final normalizedExpectedColor = _normalizeColor(expectedColor);

        Logger.info(
          '    - Comparing "$normalizedObservedColor" vs "$normalizedExpectedColor"',
        );

        if (_colorsMatch(normalizedObservedColor, normalizedExpectedColor)) {
          Logger.info('    - ✅ MATCH FOUND for ${drugResult.drugName}!');
          possibleSubstances.add(drugResult.drugName);
          break; // Don't add the same substance multiple times
        }
      }
    }

    // Calculate confidence based on matches and specificity
    if (possibleSubstances.isEmpty) {
      // Check for "no change" or "no color change" scenarios
      if (_isNoChangeColor(normalizedObservedColor)) {
        for (final drugResult in reagent.drugResults) {
          if (_isNoChangeDescription(drugResult.color)) {
            possibleSubstances.add(drugResult.drugName);
          }
        }
        confidence = possibleSubstances.isNotEmpty ? 75 : 20;
      } else {
        confidence = 20; // Low confidence for unknown results
        possibleSubstances.add('Unknown substance or impure sample');
      }
    } else {
      // Higher confidence for specific matches, lower for multiple matches
      confidence = possibleSubstances.length == 1 ? 85 : 65;
    }

    Logger.info('🔍 Final Analysis Results:');
    Logger.info('  - Possible Substances: $possibleSubstances');
    Logger.info('  - Confidence: $confidence%');

    return {'substances': possibleSubstances, 'confidence': confidence};
  }

  String _normalizeColor(String color) {
    return color
        .toLowerCase()
        .trim()
        .replaceAll(' ', '')
        .replaceAll('clear', 'nochange')
        .replaceAll('no change', 'nochange')
        .replaceAll('no color change', 'nochange')
        .replaceAll('no instant reaction', 'nochange');
  }

  List<String> _extractColorsFromDescription(String colorDescription) {
    // Extract individual colors from descriptions like "orange > brown" or "purple/brown"
    final colors = colorDescription
        .toLowerCase()
        .trim()
        .split(RegExp(r'[>\-/,]'))
        .map((color) => color.trim())
        .where((color) => color.isNotEmpty && color != 'instant')
        .toList();

    // Also add the full description as a potential match for compound colors
    final fullDescription = colorDescription.toLowerCase().trim();
    if (!colors.contains(fullDescription)) {
      colors.add(fullDescription);
    }

    return colors;
  }

  bool _colorsMatch(String observed, String expected) {
    // Direct match
    if (observed == expected) return true;

    // Handle compound colors (e.g., "yellow-green" matches "yellow > green")
    if (_isCompoundColorMatch(observed, expected)) return true;

    // Handle color variations and synonyms
    final colorSynonyms = {
      'red': ['red', 'redorange', 'orange'],
      'orange': ['orange', 'redorange', 'red'],
      'brown': ['brown', 'brownish'],
      'purple': ['purple', 'violet'],
      'black': ['black', 'darkbrown'],
      'yellow': ['yellow', 'lightyellow', 'yellowish'],
      'green': ['green', 'lightgreen', 'palegreen'],
      'blue': ['blue', 'lightblue', 'darkblue'],
      'pink': ['pink', 'magenta'],
      'grey': ['grey', 'gray'],
    };

    for (final entry in colorSynonyms.entries) {
      if (entry.value.contains(observed) && entry.value.contains(expected)) {
        return true;
      }
    }

    return false;
  }

  bool _isCompoundColorMatch(String observed, String expected) {
    // Handle compound colors like "yellow-green" matching "yellow > green"
    final observedColors = observed
        .split(RegExp(r'[-/]'))
        .map((c) => c.trim())
        .toList();
    final expectedColors = expected
        .split(RegExp(r'[>\-/,]'))
        .map((c) => c.trim())
        .toList();

    // If observed is a compound color, check if all parts match expected progression
    if (observedColors.length > 1) {
      // For "yellow-green", check if it matches "yellow > green" progression
      for (int i = 0; i < observedColors.length; i++) {
        for (int j = 0; j < expectedColors.length; j++) {
          if (_normalizeColor(observedColors[i]) ==
              _normalizeColor(expectedColors[j])) {
            // If we find a match for the first color, check if the next colors also match
            if (i + 1 < observedColors.length &&
                j + 1 < expectedColors.length) {
              if (_normalizeColor(observedColors[i + 1]) ==
                  _normalizeColor(expectedColors[j + 1])) {
                return true;
              }
            } else {
              return true; // Single color match is sufficient
            }
          }
        }
      }
    }

    // Check if any individual color from observed matches any from expected
    for (final obsColor in observedColors) {
      for (final expColor in expectedColors) {
        if (_normalizeColor(obsColor) == _normalizeColor(expColor)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _isNoChangeColor(String color) {
    final noChangeColors = ['nochange', 'clear', 'clearnochange'];
    return noChangeColors.contains(color);
  }

  bool _isNoChangeDescription(String description) {
    final lowerDescription = description.toLowerCase();
    return lowerDescription.contains('no color change') ||
        lowerDescription.contains('no change') ||
        lowerDescription.contains('no instant reaction');
  }

  void reset() {
    state = const TestResultInitial();
  }
}
