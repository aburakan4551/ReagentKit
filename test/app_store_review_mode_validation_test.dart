import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reagentkit/core/services/safe_store_sanitizer.dart';

void main() {
  SharedPreferences.setMockInitialValues({});

  group('App Store Review Mode Strict Validation Tests', () {
    setUp(() {
      SafeStoreSanitizer.safeStoreMode = true;
      SafeStoreSanitizer.appStoreReviewMode = true;
    });

    tearDown(() {
      SafeStoreSanitizer.safeStoreMode = false;
      SafeStoreSanitizer.appStoreReviewMode = false;
    });

    test('1. Strictly asserts NO forbidden English or Arabic terms appear in sanitized output', () {
      final dangerousTexts = [
        'Heroin detection test',
        'Cocaine presence in sample',
        'Cannabis botanical analysis',
        'THC compound',
        'Diazepam reference markers',
        'Narcotics testing workflow',
        'Opiates laboratory test',
        'Amphetamine references',
        'Methamphetamine reference compounds',
        'MDMA compound test',
        'LSD chemical reagent',
        'كشف هيروين',
        'فحص الكوكايين',
        'عينة حشيش',
        'تحليل القات',
        'المخدرات والمؤثرات العقلية',
        'ديازيبام وبنزوديازيبين',
        'أفيونات ومواد مخدرة',
        'كشف السموم وتحليل مخدرات',
        'مادة إم دي إم إيه',
        'كاشف الـ THC والـ LSD',
      ];

      final forbiddenKeywords = [
        'heroin', 'cocaine', 'cannabis', 'thc', 'diazepam', 'narcotic', 'opiate',
        'amphetamine', 'methamphetamine', 'mdma', 'lsd',
        'هيروين', 'كوكايين', 'حشيش', 'قات', 'مخدر', 'ديازيبام', 'بنزوديازيبين',
        'أفيون', 'سموم', 'إم دي إم إيه', 'المؤثرات العقلية'
      ];

      for (final text in dangerousTexts) {
        final sanitized = SafeStoreSanitizer.sanitize(text);
        
        for (final keyword in forbiddenKeywords) {
          expect(
            sanitized.toLowerCase().contains(keyword.toLowerCase()),
            isFalse,
            reason: 'Sanitized text "$sanitized" still contains forbidden keyword "$keyword" (from source: "$text")',
          );
        }
      }
    });

    test('2. Strictly asserts original test names do not appear in review mode', () {
      final testNames = {
        'Marquis Test': 'Reagent A',
        'Mecke Test': 'Reagent B',
        'Scott Test': 'Reagent C',
        'Vitali-Morin': 'Organic Analysis Kit',
        'Duquenois-Levine': 'Botanical Analysis Kit',
        'Simon Test': 'Analytical Reagent Kit',
        'Ehrlich Test': 'Laboratory Indicator Kit',
        'Ferric Sulfate Test': 'Chemical Analysis Kit',
        'كاشف ماركيز': 'الكاشف أ',
        'اختبار ماركيز': 'الكاشف أ',
        'كاشف ميكي': 'الكاشف ب',
        'اختبار ميكي': 'الكاشف ب',
        'كاشف سكوت': 'الكاشف ج',
        'اختبار سكوت': 'الكاشف ج',
        'فيتالي مورين': 'حقيبة التحليل العضوي',
        'دوكينوا-ليفين': 'حقيبة التحليل النباتي',
        'كاشف سايمون': 'حقيبة الكواشف التحليلية',
        'اختبار سايمون': 'حقيبة الكواشف التحليلية',
        'كاشف إيرليخ': 'حقيبة المؤشرات المخبرية',
        'اختبار إيرليخ': 'حقيبة المؤشرات المخبرية',
        'كاشف كبريتات الحديد': 'حقيبة التحليل الكيميائي',
        'اختبار كبريتات الحديد': 'حقيبة التحليل الكيميائي',
      };

      testNames.forEach((originalName, replacement) {
        final sanitized = SafeStoreSanitizer.sanitize(originalName);
        expect(sanitized, contains(replacement));
        expect(sanitized.contains(originalName), isFalse);
      });
    });

    test('3. Verifies share/export text and AI output patterns are fully sanitized', () {
      final rawAiOutput = 'AI Interpretation: Possible Substances Detected - Heroin (95% confidence). Color Match: Purple. Stability Index: Stable.';
      final sanitizedAi = SafeStoreSanitizer.sanitize(rawAiOutput);

      expect(sanitizedAi.toLowerCase().contains('heroin'), isFalse);
      expect(sanitizedAi.toLowerCase().contains('confidence'), isFalse);
      expect(sanitizedAi.toLowerCase().contains('ai interpretation'), isFalse);
      expect(sanitizedAi.toLowerCase().contains('possible substances'), isFalse);

      expect(sanitizedAi, contains('Analytical Observation'));
      expect(sanitizedAi, contains('Observed Analytical Pattern'));
    });
  });
}
