class DatasetParsingException implements Exception {
  final String reagentId;
  final String field;
  final Object error;

  const DatasetParsingException({
    required this.reagentId,
    required this.field,
    required this.error,
  });

  @override
  String toString() {
    return 'DatasetParsingException(reagentId: $reagentId, field: $field, error: $error)';
  }
}
