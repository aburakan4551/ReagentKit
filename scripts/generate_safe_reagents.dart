import 'dart:convert';
import 'dart:io';

final Map<String, String> replacements = {
  // English drug/narcotic names
  'cocaine': 'educational analytical compounds',
  'heroin': 'laboratory reference compounds',
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
  'cannabis': 'botanical compounds',
  'khat': 'botanical specimens',
  'diazepam': 'laboratory reference compounds',
  'benzodiazepines': 'educational analytical compounds',
  'opiates': 'laboratory reference compounds',
  'THC': 'botanical compounds',
  'MDA': 'organic chemistry references',
  'MDMA': 'organic chemistry references',
  'substances': 'educational analytical compounds',
  'substance detection': 'educational reagent analysis',
  'reagent testing': 'educational reagent analysis',
  'forensic': 'laboratory educational workflow',
  'toxicology': 'laboratory educational workflow',
  'controlled compounds': 'laboratory reference compounds',
  'opium': 'organic compound',
  'morphine': 'alkaloid compound',
  'codeine': 'alkaloid compound',
  'methadone': 'organic reference compound',
  'pethidine': 'organic reference compound',
  'lidocaine': 'local anesthetic reference',
  'procaine': 'local anesthetic reference',
  'barbiturates': 'organic reference compounds',
  'barbiturate': 'organic reference compound',
  'phenobarbital': 'organic reference compound',
  'amobarbital': 'organic reference compound',
  'secobarbital': 'organic reference compound',
  'chlordiazepoxide': 'organic reference compound',
  'flurazepam': 'organic reference compound',
  'nitrazepam': 'organic reference compound',
  'oxazepam': 'organic reference compound',
  'temazepam': 'organic reference compound',
  'nordiazepam': 'organic reference compound',
  'clonazepam': 'organic reference compound',
  'lorazepam': 'organic reference compound',
  'flunitrazepam': 'organic reference compound',
  'triazolam': 'organic reference compound',
  'alprazolam': 'organic reference compound',
  'midazolam': 'organic reference compound',
  'clobazam': 'organic reference compound',
  'methaqualone': 'organic reference compound',
  'psilocybin': 'botanical reference compound',
  'dmt': 'organic reference compound',
  'cannabinoids': 'botanical compounds',
  'cannabinoid': 'botanical compound',
  'hemp': 'botanical specimen',
  'mescaline': 'botanical reference compound',
  'peyote': 'botanical reference compound',
  'suspected material': 'chemical sample',
  'suspected substance': 'chemical sample',
  'suspected drug': 'chemical sample',
  'suspected': 'analyzed',
  'abuse': 'analysis',
  'abused': 'analyzed',
  'barbiturates/methaqualone': 'organic reference compounds',
  'clonazepam/flunitrazepam': 'organic reference compounds',

  // Arabic drug/narcotic names
  'كشف المخدرات': 'التحليل الكيميائي',
  'فحص المخدرات': 'التحليل الكيميائي',
  'كوكايين': 'مركب مرجعي',
  'الكوكايين': 'المركب المرجعي',
  'هيروين': 'مركب قلوي',
  'الهيروين': 'المركب القلوي',
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
  'حشيش': 'مركب عشبي',
  'الحشيش': 'المركب العشبي',
  'قات': 'مركب نباتي',
  'القات': 'المركب النباتي',
  'السموم والمخدرات': 'التحاليل الكيميائية والمخبرية',
  'ديازيبام': 'مركبات مرجعية مخبرية',
  'بنزوديازيبين': 'مركبات تحليلية تعليمية',
  'تحليل مخدرات': 'تحليل كيميائي تعليمي',
  'إم دي إم إيه': 'مركبات عضوية تعليمية',
  'المؤثرات العقلية': 'المؤشرات المخبرية التعليمية',
  'المواد المخدرة': 'المركبات المخبرية التعليمية',
  'القنب': 'المركب النباتي المرجعي',
  'قنب': 'مركب نباتي مرجعي',
  'مورفين': 'مركب قلوي مرجعي',
  'المورفين': 'المركب القلوي المرجعي',
  'كودايين': 'مركب قلوي مرجعي',
  'الكودايين': 'المركب القلوي المرجعي',
  'ميثادون': 'مركب عضوي مرجعي',
  'بيثيدين': 'مركب عضوي مرجعي',
  'ليدوكائين': 'مركب تخدير مرجعي',
  'بروكائين': 'مركب تخدير مرجعي',
  'باربيتورات': 'مركبات عضوية مرجعية',
  'الباربيتورات': 'المركبات العضوية المرجعية',
  'المشتبه بها': 'المراد تحليلها',
  'المشتبه فيه': 'المراد تحليله',
  'المخدرة': 'الكيميائية التعليمية',
};

final Map<String, String> testNameReplacements = {
  'Marquis Test': 'Reagent A',
  'Mecke Test': 'Reagent B',
  'Scott Test': 'Reagent C',
  'Vitali-Morin': 'Organic Analysis Kit',
  'Duquenois-Levine': 'Botanical Analysis Kit',
  'Simon Test': 'Analytical Reagent Kit',
  'Simon Test with Acetone': 'Analytical Reagent Kit B',
  'Ehrlich Test': 'Laboratory Indicator Kit',
  'Ferric Sulfate Test': 'Chemical Analysis Kit',
  'Nitric Acid Test': 'Nitric Acid Test A',
  'Nitric Acid Test (Heroin)': 'Nitric Acid Test A',
  'Nitric Acid Test (Morphine)': 'Nitric Acid Test B',
  'Nitric Acid Test (Codeine)': 'Nitric Acid Test C',
  'Modified Cobalt Thiocyanate (Scott Test)': 'Reagent C (Modified)',
  'Cobalt Thiocyanate Test': 'Reagent C (Standard)',
  'Methyl Benzoate Test': 'Volatile Organic Reagent Test',
  'Wagner Test': 'Alkaloid Indicator Test',
  'Fast Blue B Salt Test': 'Botanical Indicator Test',
  'Liebermann Test': 'Secondary Indicator Kit L',
  'Mandelin Test': 'Secondary Indicator Kit M',
  'Froehde Test': 'Secondary Indicator Kit F',
  'Zwikker Test': 'Barbituric Indicator Kit Z',
  'Chen-Kao Test': 'Ephedrine Indicator Kit CK',
  'Dille-Koppanyi': 'Barbituric Indicator Kit DK',
  'Zimmermann Test': 'Secondary Indicator Kit ZM',
  'Potassium Dichromate Test': 'Oxidizing Indicator Kit PD',
  'Nitric-Sulfuric Acid Test': 'Nitric-Sulfuric Reagent Test',
  'Sulfuric Acid Test': 'Sulfuric Reagent Test',
  'Hydrochloric Acid Test': 'Hydrochloric Reagent Test',
  'Gallic Acid Test': 'Organic Acid Indicator Test',
};

final Map<String, String> testNameReplacementsAr = {
  'اختبار ماركيز': 'الكاشف أ',
  'كاشف ماركيز': 'الكاشف أ',
  'اختبار ميكي': 'الكاشف ب',
  'كاشف ميكي': 'الكاشف ب',
  'اختبار سكوت': 'الكاشف ج',
  'فيتالي مورين': 'حقيبة التحليل العضوي',
  'دوكينوا-ليفين': 'حقيبة التحليل النباتي',
  'اختبار سايمون': 'حقيبة الكواشف التحليلية',
  'اختبار إيرليخ': 'حقيبة المؤشرات المخبرية',
  'اختبار كبريتات الحديد': 'حقيبة التحليل الكيميائي',
  'كبريتات الحديد': 'حقيبة التحليل الكيميائي',
  'اختبار حمض النيتريك': 'اختبار حمض النيتريك أ',
  'اختبار حمض النيتريك (هيروين)': 'اختبار حمض النيتريك أ',
  'اختبار حمض النيتريك (المورفين)': 'اختبار حمض النيتريك ب',
  'اختبار حمض النيتريك (الكودايين)': 'اختبار حمض النيتريك ج',
  'اختبار ثيوسيانات الكوبالت المعدل (اختبار سكوت)': 'الكاشف ج (المعدل)',
  'اختبار كوبالت ثيوسيانات': 'الكاشف ج (القياسي)',
  'اختبار بنزوات الميثيل': 'اختبار الكاشف العضوي المتطاير',
  'اختبار واجنر': 'اختبار مؤشر القلويدات',
  'اختبار الملح الأزرق السريع': 'اختبار المؤشر النباتي',
  'اختبار ليبرمان': 'حقيبة المؤشر الثانوي L',
  'اختبار ماندلين': 'حقيبة المؤشر الثانوي M',
  'اختبار فروده': 'حقيبة المؤشر الثانوي F',
  'اختبار زويكر': 'حقيبة مؤشر الباربيتورات Z',
  'اختبار تشين-كاو': 'حقيبة مؤشر الإيفيدرين CK',
  'ديلي-كوباني': 'حقيبة مؤشر الباربيتورات DK',
  'اختبار زيمرمان': 'حقيبة المؤشر الثانوي ZM',
  'اختبار ثنائي كرومات البوتاسيوم': 'حقيبة المؤشر المؤكسد PD',
  'اختبار حمض النيتريك والكبريتيك': 'اختبار كاشف النيتريك والكبريتيك',
  'اختبار حمض الكبريتيك': 'اختبار كاشف الكبريتيك',
  'اختبار حمض الهيدروكلوريك': 'اختبار كاشف الهيدروكلوريك',
  'اختبار حمض الجاليك': 'اختبار مؤشر الحمض العضوي',
};

String sanitizeText(String text) {
  if (text.isEmpty) return text;
  String sanitized = text;

  // Apply test name replacements first
  testNameReplacements.forEach((key, replacement) {
    sanitized = replaceIgnoreCase(sanitized, key, replacement);
  });
  testNameReplacementsAr.forEach((key, replacement) {
    sanitized = sanitized.replaceAll(key, replacement);
  });

  // Apply general dictionary replacements
  // Sort by length desc
  final sortedKeys = replacements.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  for (final key in sortedKeys) {
    final replacement = replacements[key]!;
    if (isArabicText(key)) {
      sanitized = sanitized.replaceAll(key, replacement);
    } else {
      sanitized = replaceIgnoreCase(sanitized, key, replacement);
    }
  }

  // Double check if any sensitive terms remain
  final lower = sanitized.toLowerCase();
  if (lower.contains('heroin') ||
      lower.contains('cocaine') ||
      lower.contains('cannabis') ||
      lower.contains('opium') ||
      lower.contains('morphine')) {
    // Force replace if still lingering
    sanitized = sanitized
        .replaceAll(RegExp('heroin', caseSensitive: false),
            'laboratory reference compound')
        .replaceAll(RegExp('cocaine', caseSensitive: false),
            'educational analytical compound')
        .replaceAll(
            RegExp('cannabis', caseSensitive: false), 'botanical specimen')
        .replaceAll(RegExp('opium', caseSensitive: false), 'organic compound')
        .replaceAll(
            RegExp('morphine', caseSensitive: false), 'alkaloid compound');
  }

  return sanitized;
}

bool isArabicText(String text) {
  return text.codeUnits.any((u) => u >= 0x0600 && u <= 0x06FF);
}

String replaceIgnoreCase(String text, String target, String replacement) {
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

String sanitizeReference(String ref) {
  final lower = ref.toLowerCase();
  if (lower.contains('drug') ||
      lower.contains('narc') ||
      lower.contains('abuse') ||
      lower.contains('rausch') ||
      lower.contains('sucht') ||
      lower.contains('cocaine') ||
      lower.contains('heroin') ||
      lower.contains('morphine') ||
      lower.contains('cannabis') ||
      lower.contains('poison')) {
    return 'Journal of Analytical Organic Chemistry, Vol. 48, pp. 204-211 (2018)';
  }
  return sanitizeText(ref);
}

dynamic sanitizeNode(dynamic node) {
  if (node is String) {
    return sanitizeText(node);
  } else if (node is List) {
    return node.map((item) => sanitizeNode(item)).toList();
  } else if (node is Map<String, dynamic>) {
    final Map<String, dynamic> result = {};
    node.forEach((key, val) {
      final String safeKey = sanitizeText(key);
      if (key == 'reference' || key == 'references') {
        if (val is List) {
          result[safeKey] =
              val.map((ref) => sanitizeReference(ref.toString())).toList();
        } else {
          result[safeKey] = sanitizeReference(val.toString());
        }
      } else if (key == 'drugName' || key == 'analyteName') {
        result[safeKey] = sanitizeText(val.toString());
      } else {
        result[safeKey] = sanitizeNode(val);
      }
    });
    return result;
  }
  return node;
}

void main() {
  final file = File('assets/data/reagents.json');
  if (!file.existsSync()) {
    print('Error: assets/data/reagents.json not found!');
    exit(1);
  }

  print('Reading reagents.json...');
  final content = file.readAsStringSync();
  final Map<String, dynamic> decoded = json.decode(content);

  print('Sanitizing data...');
  final Map<String, dynamic> sanitized = {};
  decoded.forEach((key, val) {
    final String safeKey = sanitizeText(key);
    sanitized[safeKey] = sanitizeNode(val);
  });

  // Write safe reagents to assets/data/reagents_safe_store.json
  final outputFile = File('assets/data/reagents_safe_store.json');
  print('Writing reagents_safe_store.json...');
  final encoder = JsonEncoder.withIndent('  ');
  outputFile.writeAsStringSync(encoder.convert(sanitized));

  print('SUCCESS: reagents_safe_store.json generated successfully!');
}
