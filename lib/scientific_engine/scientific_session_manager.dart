import 'color_matcher.dart';
import 'confidence_calculator.dart';
import 'reagent_interpreter.dart';
import 'scientific_state_machine.dart';
import 'scientific_logger.dart';

class ScientificSessionManager {
  final ScientificStateMachine stateMachine = ScientificStateMachine();
  final List<RGBColor> _colorHistory = [];
  final List<double> _brightnessHistory = [];
  
  static const int maxHistorySize = 10;
  
  double _currentStabilityIndex = 1.0;
  double _currentAmbientBrightness = 0.8;
  double _currentExposure = 0.5;

  double get stabilityIndex => _currentStabilityIndex;
  double get ambientBrightness => _currentAmbientBrightness;
  double get exposure => _currentExposure;

  void startSession() {
    ScientificLogger.info('Session', 'Starting new analysis session');
    _colorHistory.clear();
    _brightnessHistory.clear();
    _currentStabilityIndex = 1.0;
    _currentAmbientBrightness = 0.8;
    _currentExposure = 0.5;
    stateMachine.reset();
  }

  void updateCalibration({
    required double ambientBrightness,
    required double exposure,
  }) {
    _currentAmbientBrightness = ambientBrightness;
    _currentExposure = exposure;
    _brightnessHistory.add(ambientBrightness);
    if (_brightnessHistory.length > maxHistorySize) {
      _brightnessHistory.removeAt(0);
    }
  }

  /// Adds a color reading to session history and updates the stability index
  void addColorObservation(RGBColor color) {
    _colorHistory.add(color);
    if (_colorHistory.length > maxHistorySize) {
      _colorHistory.removeAt(0);
    }

    _calculateStability();
  }

  void _calculateStability() {
    if (_colorHistory.length < 3) {
      _currentStabilityIndex = 1.0; // Assume stable initially
      return;
    }

    // 1. Calculate mean R, G, B
    double meanR = 0;
    double meanG = 0;
    double meanB = 0;
    for (final col in _colorHistory) {
      meanR += col.r;
      meanG += col.g;
      meanB += col.b;
    }
    meanR /= _colorHistory.length;
    meanG /= _colorHistory.length;
    meanB /= _colorHistory.length;

    final meanColor = RGBColor(meanR.round(), meanG.round(), meanB.round());

    // 2. Calculate average Delta E distance from mean color
    double totalDistance = 0;
    for (final col in _colorHistory) {
      totalDistance += ColorMatcher.calculateDeltaE(col, meanColor);
    }
    final avgDistance = totalDistance / _colorHistory.length;

    // 3. Convert distance to stability index (lower distance = higher stability)
    // If avgDistance is <= 2.0 Delta E, stability is 1.0
    // If avgDistance is >= 15.0 Delta E, stability is 0.0
    if (avgDistance <= 2.0) {
      _currentStabilityIndex = 1.0;
    } else if (avgDistance >= 15.0) {
      _currentStabilityIndex = 0.0;
    } else {
      _currentStabilityIndex = 1.0 - ((avgDistance - 2.0) / 13.0);
    }

    ScientificLogger.debug('Session', 
      'Stability recalculated: stabilityIndex=${_currentStabilityIndex.toStringAsFixed(3)}, avgDistance=${avgDistance.toStringAsFixed(2)}'
    );
  }

  /// Runs the reagent test interpretation with the collected session data
  InterpretationResult performAnalysis({
    required List<ReagentReactionTarget> targets,
    double? customAiConfidence,
  }) {
    stateMachine.transitionToAnalyzing();
    
    if (_colorHistory.isEmpty) {
      final errResult = InterpretationResult(
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
        message: 'No color observation captured.',
        messageAr: 'لم يتم التقاط أي قراءة لونية.',
      );
      stateMachine.transitionToFailed('No color data');
      return errResult;
    }

    // Use the latest observed color
    final observedColor = _colorHistory.last;

    final result = ReagentInterpreter.interpret(
      observedColor: observedColor,
      targets: targets,
      stabilityIndex: _currentStabilityIndex,
      customAiConfidence: customAiConfidence,
      ambientBrightness: _currentAmbientBrightness,
      cameraExposure: _currentExposure,
    );

    stateMachine.transitionToCompleted(result);
    return result;
  }
}
