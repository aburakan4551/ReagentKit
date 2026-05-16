class SafetyInstructionsModel {
  final String reagentName;
  final List<String> equipment;
  final List<String> equipmentAr;
  final List<String> handlingProcedures;
  final List<String> handlingProceduresAr;
  final List<String> specificHazards;
  final List<String> specificHazardsAr;
  final List<String> storage;
  final List<String> storageAr;
  final List<String> instructions;
  final List<String> instructionsAr;

  const SafetyInstructionsModel({
    required this.reagentName,
    required this.equipment,
    required this.equipmentAr,
    required this.handlingProcedures,
    required this.handlingProceduresAr,
    required this.specificHazards,
    required this.specificHazardsAr,
    required this.storage,
    required this.storageAr,
    required this.instructions,
    required this.instructionsAr,
  });

  // Convert from JSON to Model
  factory SafetyInstructionsModel.fromJson(
    String reagentName,
    Map<String, dynamic> json,
  ) {
    return SafetyInstructionsModel(
      reagentName: reagentName,
      equipment: List<String>.from(json['equipment'] as List? ?? []),
      equipmentAr: List<String>.from(json['equipment_ar'] as List? ?? []),
      handlingProcedures: List<String>.from(
        json['handlingProcedures'] as List? ?? [],
      ),
      handlingProceduresAr: List<String>.from(
        json['handlingProcedures_ar'] as List? ?? [],
      ),
      specificHazards: List<String>.from(
        json['specificHazards'] as List? ?? [],
      ),
      specificHazardsAr: List<String>.from(
        json['specificHazards_ar'] as List? ?? [],
      ),
      storage: List<String>.from(json['storage'] as List? ?? []),
      storageAr: List<String>.from(json['storage_ar'] as List? ?? []),
      instructions: List<String>.from(json['instructions'] as List? ?? []),
      instructionsAr: List<String>.from(json['instructions_ar'] as List? ?? []),
    );
  }

  // Convert Model to JSON
  Map<String, dynamic> toJson() {
    return {
      'equipment': equipment,
      'equipment_ar': equipmentAr,
      'handlingProcedures': handlingProcedures,
      'handlingProcedures_ar': handlingProceduresAr,
      'specificHazards': specificHazards,
      'specificHazards_ar': specificHazardsAr,
      'storage': storage,
      'storage_ar': storageAr,
      'instructions': instructions,
      'instructions_ar': instructionsAr,
    };
  }

  // Get localized equipment list
  List<String> getEquipment(bool isArabic) {
    return isArabic ? equipmentAr : equipment;
  }

  // Get localized handling procedures
  List<String> getHandlingProcedures(bool isArabic) {
    return isArabic ? handlingProceduresAr : handlingProcedures;
  }

  // Get localized specific hazards
  List<String> getSpecificHazards(bool isArabic) {
    return isArabic ? specificHazardsAr : specificHazards;
  }

  // Get localized storage instructions
  List<String> getStorage(bool isArabic) {
    return isArabic ? storageAr : storage;
  }

  // Get localized test instructions
  List<String> getInstructions(bool isArabic) {
    return isArabic ? instructionsAr : instructions;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SafetyInstructionsModel &&
        other.reagentName == reagentName &&
        _listEquals(other.equipment, equipment) &&
        _listEquals(other.equipmentAr, equipmentAr) &&
        _listEquals(other.handlingProcedures, handlingProcedures) &&
        _listEquals(other.handlingProceduresAr, handlingProceduresAr) &&
        _listEquals(other.specificHazards, specificHazards) &&
        _listEquals(other.specificHazardsAr, specificHazardsAr) &&
        _listEquals(other.storage, storage) &&
        _listEquals(other.storageAr, storageAr) &&
        _listEquals(other.instructions, instructions) &&
        _listEquals(other.instructionsAr, instructionsAr);
  }

  @override
  int get hashCode {
    return reagentName.hashCode ^
        equipment.hashCode ^
        equipmentAr.hashCode ^
        handlingProcedures.hashCode ^
        handlingProceduresAr.hashCode ^
        specificHazards.hashCode ^
        specificHazardsAr.hashCode ^
        storage.hashCode ^
        storageAr.hashCode ^
        instructions.hashCode ^
        instructionsAr.hashCode;
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
    return 'SafetyInstructionsModel(reagentName: $reagentName, equipment: ${equipment.length}, procedures: ${handlingProcedures.length}, hazards: ${specificHazards.length}, storage: ${storage.length}, instructions: ${instructions.length})';
  }
}
