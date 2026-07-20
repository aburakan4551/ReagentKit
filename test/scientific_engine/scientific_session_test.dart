import 'package:flutter_test/flutter_test.dart';
import 'package:reagentkit/scientific_engine/color_matcher.dart';
import 'package:reagentkit/scientific_engine/reagent_interpreter.dart';
import 'package:reagentkit/scientific_engine/scientific_session_manager.dart';
import 'package:reagentkit/scientific_engine/scientific_state_machine.dart';
import 'package:reagentkit/scientific_engine/confidence_calculator.dart';

void main() {
  group('ScientificStateMachine Tests', () {
    test('Initial state is idle', () {
      final sm = ScientificStateMachine();
      expect(sm.state, ScientificAnalysisState.idle);
      expect(sm.result, isNull);
      expect(sm.errorMessage, isNull);
    });

    test('Valid transition sequence and listeners notification', () {
      final sm = ScientificStateMachine();
      final statesVisited = <ScientificAnalysisState>[];

      sm.addListener((state) {
        statesVisited.add(state);
      });

      sm.transitionToCalibrating();
      expect(sm.state, ScientificAnalysisState.calibrating);

      sm.transitionToAnalyzing();
      expect(sm.state, ScientificAnalysisState.analyzing);

      const mockResult = InterpretationResult(
        deltaE: 1.0,
        confidence: ConfidenceResult(
          colorMatchConfidence: 1.0,
          aiInterpretationConfidence: 0.95,
          stabilityIndex: 1.0,
          overallConfidence: 0.98,
          confidenceRating: 'High',
          isReliable: true,
        ),
        interpretationCategory: 'Reference Match',
        message: 'Test success',
        messageAr: 'نجاح الاختبار',
      );

      sm.transitionToCompleted(mockResult);
      expect(sm.state, ScientificAnalysisState.completed);
      expect(sm.result, mockResult);

      expect(statesVisited, [
        ScientificAnalysisState.calibrating,
        ScientificAnalysisState.analyzing,
        ScientificAnalysisState.completed,
      ]);
    });

    test('Transition to low confidence when result is not reliable', () {
      final sm = ScientificStateMachine();
      sm.transitionToCalibrating();
      sm.transitionToAnalyzing();

      const mockLowConfResult = InterpretationResult(
        deltaE: 14.0,
        confidence: ConfidenceResult(
          colorMatchConfidence: 0.1,
          aiInterpretationConfidence: 0.1,
          stabilityIndex: 0.2,
          overallConfidence: 0.15,
          confidenceRating: 'Low',
          isReliable: false,
        ),
        interpretationCategory: 'Low Reliability',
        message: 'Test low conf',
        messageAr: 'ثقة منخفضة',
      );

      sm.transitionToCompleted(mockLowConfResult);
      expect(sm.state, ScientificAnalysisState.lowConfidence);
      expect(sm.result, mockLowConfResult);
    });

    test('Reset returns state machine to idle', () {
      final sm = ScientificStateMachine();
      sm.transitionToFailed('Some error');
      expect(sm.state, ScientificAnalysisState.failed);
      expect(sm.errorMessage, 'Some error');

      sm.reset();
      expect(sm.state, ScientificAnalysisState.idle);
      expect(sm.errorMessage, isNull);
    });
  });

  group('ScientificSessionManager Tests', () {
    late ScientificSessionManager manager;
    final targets = [
      const ReagentReactionTarget(
        analyteName: 'Test Target',
        colorText: 'purple',
        colorTextAr: 'أرجواني',
      )
    ];

    setUp(() {
      manager = ScientificSessionManager();
      manager.startSession();
    });

    test('StartSession initializes fields', () {
      expect(manager.stabilityIndex, 1.0);
      expect(manager.ambientBrightness, 0.8);
      expect(manager.exposure, 0.5);
      expect(manager.stateMachine.state, ScientificAnalysisState.idle);
    });

    test('UpdateCalibration updates environment properties', () {
      manager.updateCalibration(ambientBrightness: 0.6, exposure: 0.45);
      expect(manager.ambientBrightness, 0.6);
      expect(manager.exposure, 0.45);
    });

    test('addColorObservation calculates high stability for static readings',
        () {
      // Adding identical colors
      for (int i = 0; i < 5; i++) {
        manager.addColorObservation(const RGBColor(128, 0, 128));
      }
      expect(manager.stabilityIndex, 1.0);
    });

    test(
        'addColorObservation reduces stability index for wild color fluctuations',
        () {
      // Add very different colors to simulate instability
      manager.addColorObservation(const RGBColor(128, 0, 128)); // Purple
      manager.addColorObservation(const RGBColor(255, 0, 0)); // Red
      manager.addColorObservation(const RGBColor(0, 255, 0)); // Green
      manager.addColorObservation(const RGBColor(0, 0, 255)); // Blue
      manager.addColorObservation(const RGBColor(255, 255, 0)); // Yellow

      expect(manager.stabilityIndex, lessThan(1.0));
    });

    test('performAnalysis fails if no colors are added', () {
      final result = manager.performAnalysis(targets: targets);
      expect(result.isSuccessful, false);
      expect(result.interpretationCategory, 'Low Reliability');
      expect(manager.stateMachine.state, ScientificAnalysisState.failed);
    });

    test('performAnalysis succeeds with reliable observations', () {
      manager.updateCalibration(ambientBrightness: 0.8, exposure: 0.5);
      manager.addColorObservation(const RGBColor(128, 0, 128));
      manager.addColorObservation(const RGBColor(128, 0, 128));
      manager.addColorObservation(const RGBColor(128, 0, 128));

      manager.stateMachine
          .transitionToCalibrating(); // State machine expects calibrating state before analyzing

      final result = manager.performAnalysis(targets: targets);
      expect(result.isSuccessful, true);
      expect(result.matchedAnalyte, 'Test Target');
      expect(manager.stateMachine.state, ScientificAnalysisState.completed);
    });
  });
}
