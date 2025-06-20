class LabelSuggestion {
  final String label;
  final String caption;
  final double confidence; // 0.0 - 1.0
  final String? reason;

  const LabelSuggestion({
    required this.label,
    required this.caption,
    required this.confidence,
    this.reason,
  });
}
