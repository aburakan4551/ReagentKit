import 'package:flutter/foundation.dart';

class SafeStoreSanitizer {
  // Flag indicating if safe store mode is currently active
  static bool safeStoreMode = false;

  // English replacements dictionary (dangerous -> safe)
  static final Map<String, String> _englishReplacements = {
    'cocaine': 'controlled compounds',
    'heroin': 'alkaloid compounds',
    'methamphetamine': 'laboratory reference compounds',
    'lsd': 'chemical reagents',
    'ecstasy': 'forensic chemistry compounds',
    'narcotics': 'educational chemistry analysis',
    'drug detection': 'laboratory reagent analysis',
    'drugs of abuse': 'educational chemistry references',
    'opioid': 'controlled compounds',
    'opioids': 'controlled compounds',
    'amphetamine': 'controlled compounds',
    'amphetamines': 'controlled compounds',
    'drug testing': 'chemical reagent analysis',
    'drug test': 'reagent analysis',
    'drug': 'compound',
    'drugs': 'compounds',
  };

  // Arabic replacements dictionary (dangerous -> safe)
  static final Map<String, String> _arabicReplacements = {
    'كشف المخدرات': 'التحليل الكيميائي',
    'فحص المخدرات': 'التحليل الكيميائي',
    'كوكايين': 'مركب مرجعي',
    'هيروين': 'مركب قلوي',
    'مواد مخدرة': 'مركبات خاضعة للتحليل',
    'مخدرات': 'مركبات خاضعة للتحليل',
    'مخدر': 'مركب خاضع للتحليل',
    'كشف السموم': 'التحليل المخبري',
    'أمفيتامين': 'مركبات أمينية',
    'امفيتامين': 'مركبات أمينية',
    'أمفيتامينات': 'مركبات أمينية',
    'أفيونات': 'مركبات قلوية',
    'افيونات': 'مركبات قلوية',
    'أفيون': 'مركب قلوي',
  };

  /// Sanitizes the input [text] by replacing sensitive terminology with safe scientific alternatives.
  /// The sanitization is applied only when [safeStoreMode] is enabled.
  static String sanitize(String text, {bool isArabic = false}) {
    if (!safeStoreMode || text.isEmpty) {
      return text;
    }

    String sanitizedText = text;

    if (isArabic) {
      // Sort keys by length descending to replace longer phrases first (e.g. "كشف المخدرات" before "مخدرات")
      final sortedKeys = _arabicReplacements.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));

      for (final key in sortedKeys) {
        final replacement = _arabicReplacements[key]!;
        // Simple case-insensitive / literal replacement for Arabic
        sanitizedText = sanitizedText.replaceAll(key, replacement);
      }
    } else {
      // English sanitization
      final sortedKeys = _englishReplacements.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));

      for (final key in sortedKeys) {
        final replacement = _englishReplacements[key]!;
        sanitizedText = _replaceIgnoreCase(sanitizedText, key, replacement);
      }
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
