import 'dart:developer' as developer;
import '../../../../scientific_engine/safe_parsers.dart';
import '../../../../scientific_engine/validation_profile.dart';
import '../../../../scientific_engine/dataset_parsing_exception.dart';
import '../../../../core/services/crash_analytics.dart';
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
      step: SafeJsonParser.safeInt(json['step']),
      instruction: SafeJsonParser.safeString(
          json['instruction'] ?? json['text'] ?? json['textEn']),
      instructionAr: SafeJsonParser.safeString(
          json['instruction_ar'] ?? json['instructionAr'] ?? json['textAr']),
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
      requiredEquipment:
          SafeJsonParser.safeList<String>(json['requiredEquipment']),
      handlingProcedures:
          SafeJsonParser.safeList<String>(json['handlingProcedures']),
      specificHazards: SafeJsonParser.safeList<String>(json['specificHazards']),
      storageRequirements: SafeJsonParser.safeList<String>(
          json['storageRequirements'] ?? json['storage']),
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

  factory ReagentTestModel.fromJson(
    Map<String, dynamic> json, {
    ValidationProfile profile = ValidationProfile.balanced,
  }) {
    try {
      // 1. Hard validation: id, reagentName, category
      final rawId = json['id'];
      if (rawId == null || rawId.toString().trim().isEmpty) {
        throw DatasetParsingException(
          reagentId: 'unknown',
          field: 'id',
          error: 'Missing or empty reagent ID',
        );
      }
      final id = rawId.toString().trim();

      final rawName = json['reagentName'] ?? json['name'];
      if (rawName == null || rawName.toString().trim().isEmpty) {
        throw DatasetParsingException(
          reagentId: id,
          field: 'reagentName',
          error: 'Missing or empty reagent name',
        );
      }
      final name = rawName.toString().trim();

      final rawCategory = json['category'] ?? json['cat'];
      if (rawCategory == null || rawCategory.toString().trim().isEmpty) {
        throw DatasetParsingException(
          reagentId: id,
          field: 'category',
          error: 'Missing or empty category',
        );
      }
      final category = rawCategory.toString().trim();

      // 2. Soft validation & parsing
      final List<ReagentTestInstructionStep> instructions = [];
      final rawInstructions =
          json['testInstructions'] ?? json['instructions'] ?? json['steps'];
      if (rawInstructions is List) {
        for (final step in rawInstructions) {
          if (step is Map<String, dynamic>) {
            try {
              instructions.add(ReagentTestInstructionStep.fromJson(step));
            } catch (e) {
              developer.log('Error parsing instruction step: $e',
                  name: 'ScientificParser');
            }
          }
        }
      }

      if (instructions.isEmpty) {
        if (profile == ValidationProfile.strict) {
          throw DatasetParsingException(
            reagentId: id,
            field: 'testInstructions',
            error: 'Empty test instructions list',
          );
        } else if (profile == ValidationProfile.balanced) {
          developer.log(
            'Soft validation warning: empty test instructions list for reagent $id',
            name: 'ScientificParser',
          );
        }
      }

      final List<DrugResultModel> reactionResults = [];
      final resultsList =
          json['reactionResults'] ?? json['drugResults'] ?? json['results'];
      if (resultsList is List) {
        for (final res in resultsList) {
          if (res is Map<String, dynamic>) {
            try {
              reactionResults.add(DrugResultModel.fromJson(res));
            } catch (e) {
              developer.log('Error parsing reaction result: $e',
                  name: 'ScientificParser');
            }
          }
        }
      }

      if (reactionResults.isEmpty) {
        if (profile == ValidationProfile.strict) {
          throw DatasetParsingException(
            reagentId: id,
            field: 'reactionResults',
            error: 'Empty reaction results list',
          );
        } else if (profile == ValidationProfile.balanced) {
          developer.log(
            'Soft validation warning: empty reaction results list for reagent $id',
            name: 'ScientificParser',
          );
        }
      }

      // Safe scientific references parsing
      final rawRefs = json['references'] ?? json['reference'] ?? json['refs'];
      final List<String> referencesList = [];
      if (rawRefs is List) {
        for (final ref in rawRefs) {
          if (ref != null) {
            final refStr = ref.toString().trim();
            if (refStr.isNotEmpty) {
              referencesList.add(refStr);
            }
          }
        }
      }

      if (referencesList.isEmpty) {
        if (profile == ValidationProfile.strict) {
          throw DatasetParsingException(
            reagentId: id,
            field: 'references',
            error: 'Empty scientific references list',
          );
        } else if (profile == ValidationProfile.balanced) {
          developer.log(
            'Soft validation warning: empty scientific references list for reagent $id',
            name: 'ScientificParser',
          );
        }
      }

      return ReagentTestModel(
        id: id,
        reagentName: name,
        reagentNameAr: SafeJsonParser.safeString(json['reagentName_ar'] ??
            json['reagentNameAr'] ??
            json['name_ar'] ??
            json['nameAr']),
        description:
            SafeJsonParser.safeString(json['description'] ?? json['desc']),
        descriptionAr: SafeJsonParser.safeString(json['description_ar'] ??
            json['descriptionAr'] ??
            json['desc_ar'] ??
            json['descAr']),
        safetyLevel: SafeJsonParser.safeString(
            json['safetyLevel'] ?? json['safety_level'] ?? 'MEDIUM'),
        safetyLevelAr: SafeJsonParser.safeString(json['safetyLevel_ar'] ??
            json['safetyLevelAr'] ??
            json['safety_level_ar'] ??
            json['safetyLevelAr']),
        category: category,
        testDuration:
            SafeJsonParser.safeInt(json['testDuration'] ?? json['duration'], 5),
        chemicals: SafeJsonParser.safeList<String>(
            json['chemicals'] ?? json['chemicalList']),
        testInstructions: instructions,
        reactionResults: reactionResults,
        references: referencesList,
        safety: ReagentTestSafetyInfo.fromJson(
            SafeJsonParser.safeMap(json['safety'] ?? json['safetyInfo'])),
      );
    } catch (e, st) {
      developer.log(
        'Invalid reagent skipped',
        error: e,
        stackTrace: st,
        name: 'ScientificParser',
      );
      CrashAnalytics.recordError(
        e,
        st,
        reason: 'Invalid scientific reagent parsing error',
      );
      rethrow;
    }
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
