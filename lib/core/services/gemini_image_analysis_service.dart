import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/logger.dart';

/// Service for image analysis using Gemini 2.0 Flash Vision API
class GeminiImageAnalysisService {
  static const String _modelName = 'gemini-2.0-flash';
  // User-provided API Key
  static const String _hardcodedApiKey = 'AIzaSyCII5fZNX4u9R-hf5bzpIWXhD8vOXgQwV8';
  
  late final GenerativeModel _model;

  GeminiImageAnalysisService({String? apiKey}) {
    Logger.info('🔧 Initializing Gemini service...');
    _initializeModel(apiKey ?? _hardcodedApiKey);
  }

  /// Create instance with Remote Config API key (or fallback to hardcoded)
  static Future<GeminiImageAnalysisService> createWithRemoteConfig() async {
    return GeminiImageAnalysisService(apiKey: _hardcodedApiKey);
  }

  void _initializeModel(String apiKey) {
    if (apiKey.isEmpty) {
      throw Exception('API_KEY_INVALID: Gemini API key is missing or invalid.');
    }

    _model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1, // Low temperature for deterministic output
        topK: 1,
        topP: 0.1,
        maxOutputTokens: 2000, // Sufficient for detailed JSON
        responseMimeType: 'application/json',
      ),
      safetySettings: [
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
      ],
    );

    Logger.info('🔧 Gemini service initialized with model: $_modelName');
  }

  /// Unified Image Analysis Function
  Future<String> analyzeImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      if (imageBytes.isEmpty) {
        throw Exception('INVALID_IMAGE: The provided image is empty or corrupted.');
      }

      final prompt = '''
Analyze this medical test image and provide a clear concise interpretation of the visible result. Detect colors, lines, indicators, and possible meanings.

CRITICAL: You must respond with ONLY valid JSON.
Required JSON format:
{
  "observed_color_description": "exact color you see in the image",
  "primary_substance": "most likely substance name",
  "identified_substances": ["list of possible substances"],
  "test_result": "Positive/Negative/Inconclusive", 
  "confidence_level": "High/Medium/Low",
  "color_match_reasoning": "why this color indicates this substance",
  "analysis_notes": "brief technical observations",
  "recommendations": "any recommended next steps"
}
Return ONLY the JSON object, nothing else.''';

      final content = [
        Content.multi([
          TextPart(prompt), 
          DataPart('image/jpeg', imageBytes)
        ]),
      ];

      Logger.info('📤 Sending request to Gemini Vision API...');
      
      final response = await _model.generateContent(content).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('NETWORK_TIMEOUT: The connection timed out.'),
      );

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('EMPTY_RESPONSE: Received empty response from Gemini API.');
      }

      final cleanedJson = _extractJsonFromResponse(response.text!);
      return cleanedJson;

    } on TimeoutException catch (e) {
      Logger.error('❌ Timeout Error: $e');
      throw Exception('NETWORK_TIMEOUT: Please check your internet connection.');
    } on GenerativeAIException catch (e) {
      Logger.error('❌ Generative AI Error: $e');
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('quota') || errorMsg.contains('429')) {
        throw Exception('QUOTA_EXCEEDED: API quota exceeded. Please try again later.');
      } else if (errorMsg.contains('permission') || errorMsg.contains('403')) {
        throw Exception('PERMISSION_DENIED: The API key does not have permission.');
      } else if (errorMsg.contains('api key') || errorMsg.contains('invalid')) {
        throw Exception('API_KEY_INVALID: The provided API key is not valid.');
      }
      throw Exception('AI_ANALYSIS_FAILED: ${e.message}');
    } catch (e) {
      Logger.error('❌ General Error: $e');
      throw Exception('AI_ANALYSIS_ERROR: Unable to analyze image. Please try again.');
    }
  }

  /// Legacy wrapper to maintain compatibility with existing UI without breaking it
  Future<String> analyzeReagentTestImage({
    required File imageFile,
    required String reagentName,
    required List<Map<String, dynamic>> drugResults,
    required Map<String, dynamic> testContext,
  }) async {
    return analyzeImage(imageFile);
  }

  /// Extracts JSON from a response that might contain markdown formatting
  String _extractJsonFromResponse(String rawResponse) {
    try {
      final jsonBlockRegex = RegExp(r'```json\s*\n(.*?)\n\s*```', dotAll: true);
      final jsonBlockMatch = jsonBlockRegex.firstMatch(rawResponse);
      if (jsonBlockMatch != null) {
        return jsonBlockMatch.group(1)?.trim() ?? rawResponse;
      }

      final codeBlockRegex = RegExp(r'```[^`]*\n(.*?)\n\s*```', dotAll: true);
      final codeBlockMatch = codeBlockRegex.firstMatch(rawResponse);
      if (codeBlockMatch != null) {
        final extracted = codeBlockMatch.group(1)?.trim() ?? rawResponse;
        if (extracted.startsWith('{') && extracted.endsWith('}')) {
          return extracted;
        }
      }

      final jsonObjectRegex = RegExp(
        r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}',
        dotAll: true,
      );
      final jsonMatches = jsonObjectRegex.allMatches(rawResponse);
      for (final match in jsonMatches) {
        final potentialJson = match.group(0);
        if (potentialJson != null && 
           (potentialJson.contains('"observed_color_description"') ||
            potentialJson.contains('"primary_substance"'))) {
          return potentialJson;
        }
      }

      return rawResponse.trim();
    } catch (e) {
      Logger.error('Error extracting JSON from response: $e');
      return rawResponse.trim();
    }
  }
}
