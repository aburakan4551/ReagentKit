import '../../features/reagent_testing/data/services/remote_config_service.dart';

class ApiKeys {
  // Gemini AI API Key - Retrieved from Remote Config with environment fallback
  static const String _envGeminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Empty default for security
  );

  /// Get Gemini API key from Remote Config with environment fallback
  static Future<String> getGeminiApiKey() async {
    try {
      final remoteConfigService = RemoteConfigService();
      return remoteConfigService.getGeminiApiKeyWithFallback();
    } catch (e) {
      // Fallback to environment variable if Remote Config fails
      return _envGeminiApiKey;
    }
  }

  /// Synchronous method for immediate access (environment only)
  static String get geminiApiKeySync => _envGeminiApiKey;

  /// Check if any Gemini API key is available
  static Future<bool> hasGeminiApiKey() async {
    final apiKey = await getGeminiApiKey();
    return apiKey.isNotEmpty;
  }

  /// Synchronous check for environment variable only
  static bool get hasGeminiApiKeySync => _envGeminiApiKey.isNotEmpty;

  /// Error message for missing API key
  static String get geminiApiKeyError =>
      'Gemini API key not found. Please set it in Firebase Remote Config or GEMINI_API_KEY environment variable.';
}
