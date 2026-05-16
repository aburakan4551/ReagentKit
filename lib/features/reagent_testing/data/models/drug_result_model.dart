import '../../domain/entities/drug_result_entity.dart';

class DrugResultModel {
  final String drugName;
  final String color;
  final String colorAr;

  const DrugResultModel({
    required this.drugName,
    required this.color,
    required this.colorAr,
  });

  // Convert from JSON to Model
  factory DrugResultModel.fromJson(Map<String, dynamic> json) {
    return DrugResultModel(
      drugName: json['drugName'] as String,
      color: json['color'] as String,
      colorAr: json['color_ar'] as String,
    );
  }

  // Convert Model to JSON
  Map<String, dynamic> toJson() {
    return {'drugName': drugName, 'color': color, 'color_ar': colorAr};
  }

  // Convert Model to Entity
  DrugResultEntity toEntity() {
    return DrugResultEntity(drugName: drugName, color: color, colorAr: colorAr);
  }

  // Convert from Entity to Model
  factory DrugResultModel.fromEntity(DrugResultEntity entity) {
    return DrugResultModel(
      drugName: entity.drugName,
      color: entity.color,
      colorAr: entity.colorAr,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrugResultModel &&
        other.drugName == drugName &&
        other.color == color &&
        other.colorAr == colorAr;
  }

  @override
  int get hashCode {
    return drugName.hashCode ^ color.hashCode ^ colorAr.hashCode;
  }

  @override
  String toString() {
    return 'DrugResultModel(drugName: $drugName, color: $color, colorAr: $colorAr)';
  }
}
