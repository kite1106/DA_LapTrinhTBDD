class ClassificationCandidate {
  final int index;
  final String? label;
  final double score;

  ClassificationCandidate({
    required this.index,
    required this.label,
    required this.score,
  });
}

class ClassificationResult {
  final List<ClassificationCandidate> topK;
  final DateTime createdAt;

  ClassificationResult({
    required this.topK,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
