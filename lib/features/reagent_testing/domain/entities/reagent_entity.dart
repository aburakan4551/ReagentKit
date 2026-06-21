import 'drug_result_entity.dart';

class ReagentEntity {
  final String id;
  final String reagentName;
  final String reagentNameAr;
  final String description;
  final String descriptionAr;
  final String safetyLevel;
  final String safetyLevelAr;
  final int testDuration;
  final List<String> chemicals;
  final List<DrugResultEntity> drugResults;
  final String category;
  final List<String> references;
  final List<String> safetyEquipment;
  final List<String> safetyProcedures;
  final List<String> safetyHazards;
  final List<String> safetyStorage;

  const ReagentEntity({
    this.id = '',
    required this.reagentName,
    required this.reagentNameAr,
    required this.description,
    required this.descriptionAr,
    required this.safetyLevel,
    required this.safetyLevelAr,
    required this.testDuration,
    required this.chemicals,
    required this.drugResults,
    required this.category,
    this.references = const [],
    this.safetyEquipment = const [],
    this.safetyProcedures = const [],
    this.safetyHazards = const [],
    this.safetyStorage = const [],
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReagentEntity &&
        other.reagentName == reagentName &&
        other.reagentNameAr == reagentNameAr &&
        other.description == description &&
        other.descriptionAr == descriptionAr &&
        other.safetyLevel == safetyLevel &&
        other.safetyLevelAr == safetyLevelAr &&
        other.testDuration == testDuration &&
        _listEquals(other.chemicals, chemicals) &&
        _listEquals(other.drugResults, drugResults) &&
        other.category == category &&
        _listEquals(other.references, references) &&
        _listEquals(other.safetyEquipment, safetyEquipment) &&
        _listEquals(other.safetyProcedures, safetyProcedures) &&
        _listEquals(other.safetyHazards, safetyHazards) &&
        _listEquals(other.safetyStorage, safetyStorage);
  }

  @override
  int get hashCode {
    return reagentName.hashCode ^
        reagentNameAr.hashCode ^
        description.hashCode ^
        descriptionAr.hashCode ^
        safetyLevel.hashCode ^
        safetyLevelAr.hashCode ^
        testDuration.hashCode ^
        chemicals.hashCode ^
        drugResults.hashCode ^
        category.hashCode ^
        references.hashCode ^
        safetyEquipment.hashCode ^
        safetyProcedures.hashCode ^
        safetyHazards.hashCode ^
        safetyStorage.hashCode;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() {
    return 'ReagentEntity(reagentName: $reagentName, description: $description, '
        'safetyLevel: $safetyLevel, testDuration: $testDuration, '
        'chemicals: $chemicals, drugResults: ${drugResults.length} results, '
        'category: $category, references: ${references.length}, safetyEquipment: ${safetyEquipment.length})';
  }
}
