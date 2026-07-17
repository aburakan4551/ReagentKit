class ScientificReference {
  final String sourceName; // e.g., "PubChem", "WHO", "NIST", "DrugBank"
  final String title;      // Reference title / substance ID
  final String description; // Brief scientific summary/context
  final String url;        // Secure link to scientific record

  const ScientificReference({
    required this.sourceName,
    required this.title,
    required this.description,
    required this.url,
  });
}
