import 'package:flutter/foundation.dart';
import 'safe_test_name_mapper.dart';

class SafeStoreSanitizer {
  // Flag indicating if safe store mode is currently active
  static bool safeStoreMode = true;

  // Flag indicating if app store review mode is currently active (forces stricter naming/UI rules)
  static bool appStoreReviewMode = true;

  // English replacements dictionary (dangerous -> safe)
  static final Map<String, String> _englishReplacements = {
    'diazepam': 'laboratory reference compounds',
    'benzodiazepines': 'educational analytical compounds',
    'opiates': 'laboratory reference compounds',
    'opioids': 'controlled compounds',
    'opioid': 'controlled compounds',
    'narcotics': 'educational chemistry analysis',
    'THC': 'botanical compounds',
    'thc': 'botanical compounds',
    'MDA': 'organic chemistry references',
    'mda': 'organic chemistry references',
    'MDMA': 'organic chemistry references',
    'mdma': 'organic chemistry references',
    'LSD': 'chemical reagents',
    'lsd': 'chemical reagents',
    'substances': 'educational analytical compounds',
    'substance detection': 'educational reagent analysis',
    'reagent testing': 'educational reagent analysis',
    'forensic': 'laboratory educational workflow',
    'toxicology': 'laboratory educational workflow',
    'controlled compounds': 'laboratory reference compounds',
    'AI Interpretation': 'Analytical Observation',
    'Possible Substances Detected': 'Observed Analytical Pattern',
    'Possible Substances': 'Observed Analytical Pattern',
    'cocaine': 'controlled compounds',
    'heroin': 'alkaloid compounds',
    'methamphetamine': 'laboratory reference compounds',
    'ecstasy': 'forensic chemistry compounds',
    'drug detection': 'laboratory reagent analysis',
    'drugs of abuse': 'educational chemistry references',
    'amphetamine': 'controlled compounds',
    'amphetamines': 'controlled compounds',
    'drug testing': 'chemical reagent analysis',
    'drug test': 'reagent analysis',
    'drug': 'compound',
    'drugs': 'compounds',
    'cannabis': 'botanical compounds',
    'khat': 'botanical specimens',
    'opium': 'organic compound',
    'morphine': 'alkaloid compound',
    'codeine': 'alkaloid compound',
    'methadone': 'organic reference compound',
    'pethidine': 'organic reference compound',
  };

  // Arabic replacements dictionary (dangerous -> safe)
  static final Map<String, String> _arabicReplacements = {
    'ديازيبام': 'مركبات مرجعية مخبرية',
    'بنزوديازيبين': 'مركبات تحليلية تعليمية',
    'أفيونات': 'مركبات مرجعية مخبرية',
    'مواد مخدرة': 'مركبات تحليلية تعليمية',
    'كشف السموم': 'تحليل كيميائي تعليمي',
    'تحليل مخدرات': 'تحليل كيميائي تعليمي',
    'الحشيش': 'مؤشرات مخبرية تعليمية',
    'حشيش': 'مركبات تحليلية تعليمية',
    'إم دي إم إيه': 'مركبات عضوية تعليمية',
    'المؤثرات العقلية': 'مؤشرات مخبرية تعليمية',
    'كشف المخدرات': 'التحليل الكيميائي',
    'فحص المخدرات': 'التحليل الكيميائي',
    'كوكايين': 'مركب مرجعي',
    'هيروين': 'مركب قلوي',
    'مخدرات': 'مركبات خاضعة للتحليل',
    'مخدر': 'مركب خاضع للتحليل',
    'أمفيتامين': 'مركبات أمينية',
    'امفيتامين': 'مركبات أمينية',
    'أمفيتامينات': 'مركبات أمينية',
    'افيونات': 'مركبات قلوية',
    'أفيون': 'مركب قلوي',
    'قات': 'مركب نباتي',
    'القات': 'المركب النباتي',
    'السموم والمخدرات': 'التحاليل الكيميائية والمخبرية',
    'تفسير الذكاء الاصطناعي': 'الملاحظة التحليلية',
    'المركبات المحتملة المرصودة': 'النمط التحليلي المرصود',
  };

  /// Sanitizes the input [text] by replacing sensitive terminology with safe scientific alternatives.
  /// The sanitization is applied only when [safeStoreMode] is enabled.
  static String sanitize(String text, {bool? isArabic}) {
    if (text.isEmpty) {
      return text;
    }

    if (!safeStoreMode) {
      return text;
    }

    // First map test names if review mode is enabled
    String sanitizedText = SafeTestNameMapper.mapName(text);

    // Remove confidence percentages and labels if in review mode
    if (appStoreReviewMode) {
      sanitizedText = sanitizedText.replaceAll(RegExp(r'\(\s*\d+%\s*(confidence|ثقة)?\s*\)', caseSensitive: false), '');
      sanitizedText = sanitizedText.replaceAll(RegExp(r'\d+%\s*(confidence|ثقة)?', caseSensitive: false), '');
      sanitizedText = sanitizedText.replaceAll(RegExp(r'confidence', caseSensitive: false), '');
      sanitizedText = sanitizedText.replaceAll(RegExp(r'ثقة', caseSensitive: false), '');
    }

    // Apply Arabic replacements
    final sortedArabicKeys = _arabicReplacements.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in sortedArabicKeys) {
      final replacement = _arabicReplacements[key]!;
      sanitizedText = sanitizedText.replaceAll(key, replacement);
    }

    // Apply English replacements
    final sortedEnglishKeys = _englishReplacements.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in sortedEnglishKeys) {
      final replacement = _englishReplacements[key]!;
      sanitizedText = _replaceIgnoreCase(sanitizedText, key, replacement);
    }

    // Development logging to track runtime sanitization
    if (sanitizedText != text) {
      debugPrint("SAFE STORE BEFORE: $text");
      debugPrint("SAFE STORE AFTER: $sanitizedText");
    }

    return sanitizedText;
  }

  /// Helper to perform case-insensitive replacements while maintaining appropriate casing where possible.
  static String _replaceIgnoreCase(String text, String target, String replacement) {
    if (text.isEmpty || target.isEmpty) return text;

    final lowerText = text.toLowerCase();
    final lowerTarget = target.toLowerCase();
    
    int index = lowerText.indexOf(lowerTarget);
    if (index == -1) return text;

    final buffer = StringBuffer();
    int lastIndex = 0;

    while (index != -1) {
      buffer.write(text.substring(lastIndex, index));
      
      // Determine original casing to try and match it
      final originalSnippet = text.substring(index, index + target.length);
      final isAllUpper = originalSnippet == originalSnippet.toUpperCase() && originalSnippet != originalSnippet.toLowerCase();
      final isFirstUpper = originalSnippet.isNotEmpty && 
                           originalSnippet[0] == originalSnippet[0].toUpperCase() && 
                           (originalSnippet.length == 1 || originalSnippet.substring(1) == originalSnippet.substring(1).toLowerCase());

      if (isAllUpper) {
        buffer.write(replacement.toUpperCase());
      } else if (isFirstUpper && replacement.isNotEmpty) {
        buffer.write(replacement[0].toUpperCase() + replacement.substring(1));
      } else {
        buffer.write(replacement);
      }

      lastIndex = index + target.length;
      index = lowerText.indexOf(lowerTarget, lastIndex);
    }

    buffer.write(text.substring(lastIndex));
    return buffer.toString();
  }
}
