class DrugResultEntity {
  final String drugName;
  final String color;
  final String colorAr;

  const DrugResultEntity({
    required this.drugName,
    required this.color,
    required this.colorAr,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrugResultEntity &&
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
    return 'DrugResultEntity(drugName: $drugName, color: $color, colorAr: $colorAr)';
  }
}
