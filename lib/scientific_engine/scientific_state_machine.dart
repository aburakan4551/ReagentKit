import 'reagent_interpreter.dart';

enum ScientificAnalysisState {
  idle,
  calibrating,
  analyzing,
  lowConfidence,
  completed,
  failed,
  datasetUnavailable,
}

class ScientificStateMachine {
  ScientificAnalysisState _state = ScientificAnalysisState.idle;
  InterpretationResult? _result;
  String? _errorMessage;

  ScientificAnalysisState get state => _state;
  InterpretationResult? get result => _result;
  String? get errorMessage => _errorMessage;

  // Listeners list for simple observer pattern in pure Dart
  final List<void Function(ScientificAnalysisState state)> _listeners = [];

  void addListener(void Function(ScientificAnalysisState state) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(ScientificAnalysisState state) listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in _listeners) {
      listener(_state);
    }
  }

  void reset() {
    _state = ScientificAnalysisState.idle;
    _result = null;
    _errorMessage = null;
    _notify();
  }

  void transitionToCalibrating() {
    if (_state == ScientificAnalysisState.idle || _state == ScientificAnalysisState.failed || _state == ScientificAnalysisState.completed) {
      _state = ScientificAnalysisState.calibrating;
      _result = null;
      _errorMessage = null;
      _notify();
    }
  }

  void transitionToAnalyzing() {
    if (_state == ScientificAnalysisState.calibrating) {
      _state = ScientificAnalysisState.analyzing;
      _notify();
    }
  }

  void transitionToCompleted(InterpretationResult result) {
    if (_state == ScientificAnalysisState.analyzing) {
      if (result.confidence.isReliable) {
        _state = ScientificAnalysisState.completed;
        _result = result;
      } else {
        _state = ScientificAnalysisState.lowConfidence;
        _result = result;
      }
      _notify();
    }
  }

  void transitionToFailed(String error) {
    _state = ScientificAnalysisState.failed;
    _errorMessage = error;
    _notify();
  }

  void transitionToDatasetUnavailable() {
    _state = ScientificAnalysisState.datasetUnavailable;
    _notify();
  }
}
