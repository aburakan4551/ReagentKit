import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class CrashAnalytics {
  static final CrashAnalytics _instance = CrashAnalytics._internal();
  factory CrashAnalytics() => _instance;
  CrashAnalytics._internal();

  static bool _useCrashlytics = false;

  static void initialize() {
    try {
      if (!kIsWeb) {
        _useCrashlytics = true;
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }
      developer.log('CrashAnalytics initialized', name: 'CrashAnalytics');
    } catch (e) {
      developer.log(
        'CrashAnalytics could not be initialized (likely Firebase is not configured): $e',
        name: 'CrashAnalytics',
      );
      _useCrashlytics = false;
    }
  }

  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    bool fatal = false,
  }) async {
    developer.log(
      'Reporting error: $exception',
      error: exception,
      stackTrace: stack,
      name: 'CrashAnalytics',
    );
    if (_useCrashlytics) {
      try {
        await FirebaseCrashlytics.instance.recordError(
          exception,
          stack,
          reason: reason,
          fatal: fatal,
        );
      } catch (e) {
        developer.log(
          'FirebaseCrashlytics failed to record error: $e',
          name: 'CrashAnalytics',
        );
      }
    }
  }

  static Future<void> log(String message) async {
    developer.log(message, name: 'CrashAnalytics');
    if (_useCrashlytics) {
      try {
        await FirebaseCrashlytics.instance.log(message);
      } catch (e) {
        developer.log(
          'FirebaseCrashlytics failed to log: $e',
          name: 'CrashAnalytics',
        );
      }
    }
  }
}
