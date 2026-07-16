import 'safe_store_sanitizer.dart';

class SafeTestNameMapper {
  static final Map<String, String> _englishMappings = {
    'Marquis Test': 'Reagent A',
    'Mecke Test': 'Reagent B',
    'Scott Test': 'Reagent C',
    'Vitali-Morin': 'Organic Analysis Kit',
    'Duquenois-Levine': 'Botanical Analysis Kit',
    'Simon Test': 'Analytical Reagent Kit',
    'Ehrlich Test': 'Laboratory Indicator Kit',
    'Ferric Sulfate Test': 'Chemical Analysis Kit',
  };

  static final Map<String, String> _arabicMappings = {
    'اختبار ماركيز': 'الكاشف أ',
    'كاشف ماركيز': 'الكاشف أ',
    'اختبار ميكي': 'الكاشف ب',
    'كاشف ميكي': 'الكاشف ب',
    'اختبار سكوت': 'الكاشف ج',
    'كاشف سكوت': 'الكاشف ج',
    'فيتالي مورين': 'حقيبة التحليل العضوي',
    'دوكينوا-ليفين': 'حقيبة التحليل النباتي',
    'اختبار سايمون': 'حقيبة الكواشف التحليلية',
    'كاشف سايمون': 'حقيبة الكواشف التحليلية',
    'اختبار إيرليخ': 'حقيبة المؤشرات المخبرية',
    'كاشف إيرليخ': 'حقيبة المؤشرات المخبرية',
    'اختبار كبريتات الحديد': 'حقيبة التحليل الكيميائي',
    'كبريتات الحديد': 'حقيبة التحليل الكيميائي',
  };

  /// Maps a test name to its safe replacement if app_store_review_mode is enabled.
  static String mapName(String text) {
    if (!SafeStoreSanitizer.appStoreReviewMode) {
      return text;
    }

    String mappedText = text;

    // Replace Arabic names
    _arabicMappings.forEach((key, replacement) {
      mappedText = mappedText.replaceAll(key, replacement);
    });

    // Replace English names (case-insensitive)
    _englishMappings.forEach((key, replacement) {
      mappedText = _replaceIgnoreCase(mappedText, key, replacement);
    });

    return mappedText;
  }

  static String _replaceIgnoreCase(
      String text, String target, String replacement) {
    if (text.isEmpty || target.isEmpty) return text;

    final lowerText = text.toLowerCase();
    final lowerTarget = target.toLowerCase();

    int index = lowerText.indexOf(lowerTarget);
    if (index == -1) return text;

    final buffer = StringBuffer();
    int lastIndex = 0;

    while (index != -1) {
      buffer.write(text.substring(lastIndex, index));

      final originalSnippet = text.substring(index, index + target.length);
      final isAllUpper = originalSnippet == originalSnippet.toUpperCase() &&
          originalSnippet != originalSnippet.toLowerCase();
      final isFirstUpper = originalSnippet.isNotEmpty &&
          originalSnippet[0] == originalSnippet[0].toUpperCase() &&
          (originalSnippet.length == 1 ||
              originalSnippet.substring(1) ==
                  originalSnippet.substring(1).toLowerCase());

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
