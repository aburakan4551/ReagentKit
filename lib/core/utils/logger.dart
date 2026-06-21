import 'dart:developer' as developer;

/// Logger utility to replace print statements in production code
class Logger {
  static const String _defaultTag = 'ReagentApp';

  /// Log info messages
  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _defaultTag,
      level: 800, // Info level
    );
  }

  /// Log error messages
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag ?? _defaultTag,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log warning messages
  static void warning(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? _defaultTag,
      level: 900, // Warning level
    );
  }

  /// Log debug messages (only in debug mode)
  static void debug(String message, {String? tag}) {
    assert(() {
      developer.log(
        message,
        name: tag ?? _defaultTag,
        level: 700, // Debug level
      );
      return true;
    }());
  }
}
