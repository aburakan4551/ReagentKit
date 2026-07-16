import 'dart:convert';
import 'scientific_constants.dart';

enum ScientificLogLevel { debug, info, warning, error }

class ScientificLogger {
  static void _log(ScientificLogLevel level, String category, String message,
      {Object? error, StackTrace? stackTrace}) {
    final logMap = {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'level': level.name.toUpperCase(),
      'category': category,
      'message': message,
      'algorithm_version': ScientificConstants.algorithmVersion,
      'dataset_version': ScientificConstants.datasetVersion,
    };

    if (error != null) {
      logMap['error'] = error.toString();
    }
    if (stackTrace != null) {
      logMap['stack_trace'] = stackTrace.toString();
    }

    // Print as a single line JSON for log ingestion/structured analysis
    // In production iOS/Flutter, this is captured by OS log or Firebase Crashlytics
    // ignore: avoid_print
    print('[ScientificEngine] ${json.encode(logMap)}');
  }

  static void debug(String category, String message) {
    _log(ScientificLogLevel.debug, category, message);
  }

  static void info(String category, String message) {
    _log(ScientificLogLevel.info, category, message);
  }

  static void warning(String category, String message) {
    _log(ScientificLogLevel.warning, category, message);
  }

  static void error(String category, String message,
      {Object? error, StackTrace? stackTrace}) {
    _log(ScientificLogLevel.error, category, message,
        error: error, stackTrace: stackTrace);
  }
}
