import '../../domain/entities/reagent_entity.dart';
import 'drug_result_model.dart';

class ReagentTestInstructionStep {
  final int step;
  final String instruction;
  final String instructionAr;

  const ReagentTestInstructionStep({
    required this.step,
    required this.instruction,
    required this.instructionAr,
  });

  factory ReagentTestInstructionStep.fromJson(Map<String, dynamic> json) {
    return ReagentTestInstructionStep(
      step: json['step'] as int? ?? 0,
      instruction: json['instruction'] as String? ?? '',
      instructionAr: json['instruction_ar'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'step': step,
    'instruction': instruction,
    'instruction_ar': instructionAr,
  };
}

class ReagentTestSafetyInfo {
  final List<String> requiredEquipment;
  final List<String> handlingProcedures;
  final List<String> specificHazards;
  final List<String> storageRequirements;

  const ReagentTestSafetyInfo({
    required this.requiredEquipment,
    required this.handlingProcedures,
    required this.specificHazards,
    required this.storageRequirements,
  });

  factory ReagentTestSafetyInfo.fromJson(Map<String, dynamic> json) {
    return ReagentTestSafetyInfo(
      requiredEquipment: List<String>.from(json['requiredEquipment'] as List? ?? []),
      handlingProcedures: List<String>.from(json['handlingProcedures'] as List? ?? []),
      specificHazards: List<String>.from(json['specificHazards'] as List? ?? []),
      storageRequirements: List<String>.from(json['storageRequirements'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'requiredEquipment': requiredEquipment,
    'handlingProcedures': handlingProcedures,
    'specificHazards': specificHazards,
    'storageRequirements': storageRequirements,
  };
}

class ReagentTestModel {
  final String id;
  final String reagentName;
  final String reagentNameAr;
  final String description;
  final String descriptionAr;
  final String safetyLevel;
  final String safetyLevelAr;
  final String category;
  final int testDuration;
  final List<String> chemicals;
  final List<ReagentTestInstructionStep> testInstructions;
  final List<DrugResultModel> reactionResults;
  final List<String> references;
  final ReagentTestSafetyInfo safety;

  const ReagentTestModel({
    required this.id,
    required this.reagentName,
    required this.reagentNameAr,
    required this.description,
    required this.descriptionAr,
    required this.safetyLevel,
    required this.safetyLevelAr,
    required this.category,
    required this.testDuration,
    required this.chemicals,
    required this.testInstructions,
    required this.reactionResults,
    required this.references,
    required this.safety,
  });

  factory ReagentTestModel.fromJson(Map<String, dynamic> json) {
    // Parsing Defense (Safe Offline Mode/Null-Safety)
    final id = json['id'] as String? ?? '';
    final name = json['reagentName'] as String? ?? '';
    if (id.isEmpty || name.isEmpty) {
      throw const FormatException('Invalid reagent JSON schema: missing id or name');
    }

    final instructions = (json['testInstructions'] as List? ?? [])
        .map((e) => ReagentTestInstructionStep.fromJson(e as Map<String, dynamic>))
        .toList();

    // Support both new `reactionResults` key and legacy `drugResults` key for compatibility
    final resultsList = json['reactionResults'] as List? ?? json['drugResults'] as List? ?? [];
    final reactionResults = resultsList
        .map((e) => DrugResultModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReagentTestModel(
      id: id,
      reagentName: name,
      reagentNameAr: json['reagentName_ar'] as String? ?? json['reagentNameAr'] as String? ?? '',
      description: json['description'] as String? ?? '',
      descriptionAr: json['description_ar'] as String? ?? json['descriptionAr'] as String? ?? '',
      safetyLevel: json['safetyLevel'] as String? ?? 'MEDIUM',
      safetyLevelAr: json['safetyLevel_ar'] as String? ?? json['safetyLevelAr'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      testDuration: (json['testDuration'] as num?)?.toInt() ?? 5,
      chemicals: List<String>.from(json['chemicals'] as List? ?? []),
      testInstructions: instructions,
      reactionResults: reactionResults,
      references: List<String>.from(json['references'] as List? ?? json['reference'] as List? ?? []),
      safety: ReagentTestSafetyInfo.fromJson(json['safety'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reagentName': reagentName,
      'reagentName_ar': reagentNameAr,
      'description': description,
      'description_ar': descriptionAr,
      'safetyLevel': safetyLevel,
      'safety_level_ar': safetyLevelAr,
      'category': category,
      'testDuration': testDuration,
      'chemicals': chemicals,
      'testInstructions': testInstructions.map((e) => e.toJson()).toList(),
      'reactionResults': reactionResults.map((e) => e.toJson()).toList(),
      'references': references,
      'safety': safety.toJson(),
    };
  }

  // Convert to ReagentEntity (Clean Architecture compatibility)
  ReagentEntity toEntity() {
    return ReagentEntity(
      id: id,
      reagentName: reagentName,
      reagentNameAr: reagentNameAr,
      description: description,
      descriptionAr: descriptionAr,
      safetyLevel: safetyLevel,
      safetyLevelAr: safetyLevelAr,
      testDuration: testDuration,
      chemicals: chemicals,
      drugResults: reactionResults.map((e) => e.toEntity()).toList(),
      category: category,
      references: references,
      safetyEquipment: safety.requiredEquipment,
      safetyProcedures: safety.handlingProcedures,
      safetyHazards: safety.specificHazards,
      safetyStorage: safety.storageRequirements,
    );
  }
}
