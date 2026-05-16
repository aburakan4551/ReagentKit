import 'dart:io';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/logger.dart';
import '../config/api_keys.dart';

class GeminiImageAnalysisService {
  static const String _modelName =
      'gemini-2.0-flash'; // Cheaper than 2.0-flash-exp
  late final GenerativeModel _model;

  GeminiImageAnalysisService({String? apiKey}) {
    Logger.info('🔧 Initializing Gemini service...');
    _initializeModel(apiKey);
  }

  /// Create instance with Remote Config API key
  static Future<GeminiImageAnalysisService> createWithRemoteConfig() async {
    try {
      Logger.info('🔑 Getting Gemini API key from Remote Config...');
      final apiKey = await ApiKeys.getGeminiApiKey();

      if (apiKey.isEmpty) {
        Logger.error(
          '❌ No Gemini API key found in Remote Config or environment',
        );
        throw Exception(
          'Gemini API key not found. Please ensure "gemini_api_key" is set in Firebase Remote Config with your Google AI API key.',
        );
      }

      Logger.info('✅ Gemini API key retrieved successfully');
      return GeminiImageAnalysisService(apiKey: apiKey);
    } catch (e) {
      Logger.error('❌ Failed to create Gemini service with Remote Config: $e');
      rethrow;
    }
  }

  void _initializeModel(String? providedApiKey) {
    String apiKey;

    if (providedApiKey != null && providedApiKey.isNotEmpty) {
      apiKey = providedApiKey;
      Logger.info('🔑 Using provided API key');
    } else {
      // Fallback to synchronous environment variable
      apiKey = ApiKeys.geminiApiKeySync;
      Logger.info('🔑 Using environment variable API key');
    }

    if (apiKey.isEmpty) {
      throw Exception(
        'Gemini API key is required but not provided. ${ApiKeys.geminiApiKeyError}',
      );
    }

    _model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.0, // Lowest temperature for most consistent JSON output
        topK: 1,
        topP: 0.1,
        maxOutputTokens: 200, // Increased for proper JSON responses
        responseMimeType: 'application/json', // Force JSON response
      ),
    );

    Logger.info('🔧 Gemini service initialized with model: $_modelName');
  }

  Future<String> analyzeImageForChemicals(File imageFile) async {
    try {
      Logger.info('🔬 Starting Gemini image analysis for chemical detection');

      // Read image file as bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Create the prompt for chemical analysis
      const String prompt = '''
Analyze chemicals in image. Return JSON:
{
  "detected_chemicals": ["chemicals"],
  "confidence_level": "high/medium/low",
  "analysis_notes": "brief description",
  "suggested_reagents": ["reagents"],
  "color_analysis": "colors seen"
}''';

      // Create content with image and text
      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      // Generate response
      final response = await _model.generateContent(content);
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from Gemini API');
      }

      Logger.info('✅ Gemini analysis completed successfully');
      return responseText;
    } catch (e) {
      Logger.error('❌ Gemini image analysis failed: $e');
      rethrow;
    }
  }

  Future<String> analyzeReagentTestImage({
    required File imageFile,
    required String reagentName,
    required List<Map<String, dynamic>> drugResults,
    required Map<String, dynamic> testContext,
  }) async {
    try {
      Logger.info(
        '🔬 Starting Gemini reagent test analysis for $reagentName...',
      );

      final imageBytes = await imageFile.readAsBytes();

      // Build the substance-color knowledge database for this reagent
      final substanceColorMap = StringBuffer();
      for (final drugResult in drugResults) {
        final substance = drugResult['drugName'] ?? 'Unknown';
        final color = drugResult['color'] ?? 'no change';
        substanceColorMap.writeln('- $substance: $color');
      }

      final prompt =
          '''
You are analyzing a $reagentName reagent test image. 

Known substance-color reactions for this reagent:
${substanceColorMap.toString()}

CRITICAL: You must respond with ONLY valid JSON, no other text, no markdown formatting, no explanations.

Required JSON format:
{
  "observed_color_description": "exact color you see in the image",
  "primary_substance": "most likely substance name",
  "identified_substances": ["list of possible substances"],
  "test_result": "Positive/Negative/Inconclusive", 
  "confidence_level": "High/Medium/Low",
  "color_match_reasoning": "why this color indicates this substance",
  "analysis_notes": "brief technical observations"
}

Return ONLY the JSON object, nothing else.''';

      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];

      Logger.info('📤 Sending request to Gemini API...');
      final response = await _model.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception(
          'Empty response from Gemini API - check API key and quota',
        );
      }

      final rawText = response.text!;
      Logger.info(
        '📥 Received response from Gemini: ${rawText.substring(0, rawText.length.clamp(0, 200))}...',
      );

      // Extract JSON from the response (in case it's wrapped in markdown or other text)
      final cleanedJson = _extractJsonFromResponse(rawText);

      Logger.info(
        '✅ Reagent test analysis completed: ${cleanedJson.length} characters',
      );
      return cleanedJson;
    } catch (e, stackTrace) {
      Logger.error('❌ Gemini reagent test analysis failed: $e');
      Logger.error('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Extracts JSON from a response that might contain markdown formatting or extra text
  String _extractJsonFromResponse(String rawResponse) {
    try {
      // First, try to find JSON within code blocks (```json ... ```)
      final jsonBlockRegex = RegExp(r'```json\s*\n(.*?)\n\s*```', dotAll: true);
      final jsonBlockMatch = jsonBlockRegex.firstMatch(rawResponse);

      if (jsonBlockMatch != null) {
        return jsonBlockMatch.group(1)?.trim() ?? rawResponse;
      }

      // Try to find JSON within any code blocks (``` ... ```)
      final codeBlockRegex = RegExp(r'```[^`]*\n(.*?)\n\s*```', dotAll: true);
      final codeBlockMatch = codeBlockRegex.firstMatch(rawResponse);

      if (codeBlockMatch != null) {
        final extracted = codeBlockMatch.group(1)?.trim() ?? rawResponse;
        // Check if the extracted content looks like JSON
        if (extracted.startsWith('{') && extracted.endsWith('}')) {
          return extracted;
        }
      }

      // Look for JSON object in the text (starting with { and ending with })
      final jsonObjectRegex = RegExp(
        r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}',
        dotAll: true,
      );
      final jsonMatches = jsonObjectRegex.allMatches(rawResponse);

      for (final match in jsonMatches) {
        final potentialJson = match.group(0);
        if (potentialJson != null) {
          // Try to validate this is proper JSON by checking structure
          if (potentialJson.contains('"observed_color_description"') ||
              potentialJson.contains('"primary_substance"')) {
            return potentialJson;
          }
        }
      }

      // If no specific JSON found, return the raw response and let the calling code handle the error
      return rawResponse.trim();
    } catch (e) {
      Logger.error('Error extracting JSON from response: $e');
      return rawResponse.trim();
    }
  }
}
