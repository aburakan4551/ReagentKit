import 'dart:convert';
import 'dart:io';

void main() async {
  // Read the current reagent data
  final reagentDataFile = File('remote_config_output/reagent_data.json');
  final reagentDataContent = await reagentDataFile.readAsString();
  final Map<String, dynamic> reagentData = json.decode(reagentDataContent);

  // Hazard translations
  final Map<String, String> hazardTranslations = {
    'Highly corrosive - contains concentrated sulfuric acid':
        'شديد التآكل - يحتوي على حمض الكبريتيك المركز',
    'Highly corrosive - contains concentrated acid':
        'شديد التآكل - يحتوي على حمض مركز',
    'Causes severe chemical burns': 'يسبب حروق كيميائية شديدة',
    'Dangerous fumes - formaldehyde': 'أبخرة خطيرة - الفورمالديهايد',
    'Dangerous fumes': 'أبخرة خطيرة',
    'Exothermic reaction': 'تفاعل طارد للحرارة',
    'Corrosive': 'مسبب للتآكل',
    'Handle with care': 'التعامل بحذر',
    'Toxic - contains Cobalt(II) thiocyanate':
        'سام - يحتوي على ثيوسيانات الكوبالت (II)',
    'Toxic - contains Selenous Acid': 'سام - يحتوي على حمض السيلينوز',
    'Causes irritation': 'يسبب تهيج',
  };

  // Standard equipment (same for all reagents)
  final standardEquipment = [
    "Chemical-resistant safety goggles",
    "Chemical-resistant gloves (nitrile or neoprene)",
    "Lab coat with long sleeves",
    "Closed-toe chemical-resistant shoes",
    "Respirator when necessary",
  ];

  final standardEquipmentAr = [
    "نظارات أمان مقاومة للمواد الكيميائية",
    "قفازات مقاومة للمواد الكيميائية (نيتريل أو نيوبرين)",
    "معطف مختبر بأكمام طويلة",
    "أحذية مغلقة مقاومة للمواد الكيميائية",
    "جهاز تنفس عند الضرورة",
  ];

  // Create safety instructions data
  final Map<String, dynamic> safetyInstructions = {};

  for (final reagentName in reagentData.keys) {
    final reagent = reagentData[reagentName] as Map<String, dynamic>;

    // Extract safety data
    final equipment = reagent['equipment'] as List<dynamic>? ?? [];
    final handlingProcedures =
        reagent['handlingProcedures'] as List<dynamic>? ?? [];
    final specificHazards = reagent['specificHazards'] as List<dynamic>? ?? [];
    final storage = reagent['storage'] as List<dynamic>? ?? [];
    final instructions = reagent['instructions'] as List<dynamic>? ?? [];

    // Translate hazards
    final hazardsAr = specificHazards.map((hazard) {
      return hazardTranslations[hazard.toString()] ?? hazard.toString();
    }).toList();

    // Create instructions translations
    final instructionsAr = _translateInstructions(
      instructions.cast<String>(),
      reagentName,
    );

    safetyInstructions[reagentName] = {
      'equipment': equipment,
      'equipment_ar': standardEquipmentAr,
      'handlingProcedures': handlingProcedures,
      'handlingProcedures_ar': _translateHandlingProcedures(
        handlingProcedures.cast<String>(),
      ),
      'specificHazards': specificHazards,
      'specificHazards_ar': hazardsAr,
      'storage': storage,
      'storage_ar': _translateStorage(storage.cast<String>()),
      'instructions': instructions,
      'instructions_ar': instructionsAr,
    };
  }

  // Write safety instructions file
  final safetyFile = File('remote_config_output/safety_instructions.json');
  await safetyFile.writeAsString(
    JsonEncoder.withIndent('  ').convert(safetyInstructions),
  );

  // Create updated reagent data without safety fields
  final Map<String, dynamic> updatedReagentData = {};

  for (final reagentName in reagentData.keys) {
    final reagent = Map<String, dynamic>.from(
      reagentData[reagentName] as Map<String, dynamic>,
    );

    // Remove safety-related fields
    reagent.remove('equipment');
    reagent.remove('handlingProcedures');
    reagent.remove('specificHazards');
    reagent.remove('storage');
    reagent.remove('instructions');

    updatedReagentData[reagentName] = reagent;
  }

  // Write updated reagent data
  final updatedReagentFile = File(
    'remote_config_output/reagent_data_updated.json',
  );
  await updatedReagentFile.writeAsString(
    JsonEncoder.withIndent('  ').convert(updatedReagentData),
  );

  print('Safety instructions extracted to safety_instructions.json');
  print('Updated reagent data saved to reagent_data_updated.json');
}

List<String> _translateHandlingProcedures(List<String> procedures) {
  final translations = <String>[];

  for (final procedure in procedures) {
    switch (procedure) {
      case 'Work under fume hood mandatory':
        translations.add('العمل تحت غطاء الدخان إجباري');
        break;
      case 'Wear acid-resistant gloves':
        translations.add('ارتداء قفازات مقاومة للأحماض');
        break;
      case 'Use safety goggles and face shield':
        translations.add('استخدام نظارات الأمان وواقي الوجه');
        break;
      case 'Keep sodium bicarbonate handy for neutralization':
        translations.add('الاحتفاظ ببيكربونات الصوديوم للتحييد');
        break;
      case 'Use only small drops':
        translations.add('استخدام قطرات صغيرة فقط');
        break;
      case 'Never mix reagent directly with water':
        translations.add('عدم خلط الكاشف مباشرة مع الماء');
        break;
      default:
        translations.add(procedure);
    }
  }

  return translations;
}

List<String> _translateStorage(List<String> storage) {
  final translations = <String>[];

  for (final item in storage) {
    switch (item) {
      case 'Store in cool, dry place':
        translations.add('التخزين في مكان بارد وجاف');
        break;
      case 'Away from flammable materials':
        translations.add('بعيداً عن المواد القابلة للاشتعال');
        break;
      case 'In dedicated acid storage cabinet':
        translations.add('في خزانة تخزين أحماض مخصصة');
        break;
      case 'Label with clear warning':
        translations.add('وضع ملصق تحذيري واضح');
        break;
      default:
        translations.add(item);
    }
  }

  return translations;
}

List<String> _translateInstructions(
  List<String> instructions,
  String reagentName,
) {
  final translations = <String>[];
  final reagentNameAr = _getReagentNameAr(reagentName);

  for (final instruction in instructions) {
    if (instruction.contains('Prepare a small sample')) {
      translations.add('تحضير عينة صغيرة من المادة للاختبار');
    } else if (instruction.contains('Add 1-2 drops of') &&
        instruction.contains('reagent')) {
      translations.add('إضافة 1-2 قطرة من كاشف $reagentNameAr إلى العينة');
    } else if (instruction.contains('Add a few drops of') &&
        instruction.contains('A')) {
      translations.add('إضافة بضع قطرات من $reagentNameAr أ، مراقبة اللون');
    } else if (instruction.contains('Add a few drops of') &&
        instruction.contains('B')) {
      translations.add('إضافة بضع قطرات من $reagentNameAr ب، الهز، المراقبة');
    } else if (instruction.contains('Add a few drops of') &&
        instruction.contains('C')) {
      translations.add(
        'إضافة بضع قطرات من $reagentNameAr ج، الهز، مراقبة اللون النهائي',
      );
    } else if (instruction.contains('Add 2 drops of') &&
        instruction.contains('A')) {
      translations.add('إضافة قطرتين من $reagentNameAr أ');
    } else if (instruction.contains('Add 1 drop of') &&
        instruction.contains('B')) {
      translations.add(
        'إضافة قطرة واحدة من $reagentNameAr ب ومراقبة تغير اللون',
      );
    } else if (instruction.contains('Add 1 drop of') &&
        instruction.contains('A')) {
      translations.add('إضافة قطرة واحدة من $reagentNameAr أ');
    } else if (instruction.contains('followed by 1 drop of')) {
      translations.add(
        'إضافة قطرة واحدة من سايمون أ متبوعة بقطرة واحدة من سايمون ب',
      );
    } else if (instruction.contains('Observe the color change')) {
      if (instruction.contains('1 minute')) {
        translations.add('مراقبة تغير اللون لمدة دقيقة واحدة');
      } else if (instruction.contains('5 minutes')) {
        translations.add('مراقبة تغير اللون لمدة تصل إلى 5 دقائق');
      } else if (instruction.contains('2 minutes')) {
        translations.add('مراقبة تغير اللون لمدة تصل إلى دقيقتين');
      } else {
        translations.add('مراقبة تغير اللون');
      }
    } else if (instruction.contains('Compare the resulting color')) {
      translations.add('مقارنة اللون الناتج مع النتائج المتوقعة');
    } else if (instruction.contains('Record your observations')) {
      translations.add('تسجيل الملاحظات والتخلص من المواد بأمان');
    } else if (instruction.contains('Place a small sample into a test tube')) {
      translations.add('وضع عينة صغيرة في أنبوب اختبار');
    } else if (instruction.contains('shake for 10 seconds')) {
      translations.add('إضافة 1-2 قطرة من موريس أ، الهز لمدة 10 ثوان');
    } else if (instruction.contains('shake and observe')) {
      translations.add('إضافة 1-2 قطرة من موريس ب، الهز ومراقبة تغير اللون');
    } else if (instruction.contains('shake, observe')) {
      translations.add('الهز ومراقبة');
    } else if (instruction.contains('shake, observe final color')) {
      translations.add('الهز ومراقبة اللون النهائي');
    } else {
      translations.add(instruction); // fallback
    }
  }

  return translations;
}

String _getReagentNameAr(String reagentName) {
  final nameMap = {
    'Marquis': 'ماركيز',
    'Gallic': 'غاليك',
    'Morris': 'موريس',
    'Scott': 'سكوت',
    'Robadope': 'روبادوب',
    'Froehde': 'فروهده',
    'Mandelin': 'مانديلين',
    'Folin': 'فولين',
    'Hofmann': 'هوفمان',
    'Zimmermann': 'زيمرمان',
    'Ehrlich': 'إيرليخ',
    'Liebermann': 'ليبرمان',
    'Mecke': 'ميكي',
    'Simon\'s': 'سايمون',
  };

  return nameMap[reagentName] ?? reagentName;
}
