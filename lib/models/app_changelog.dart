class AppChangeEntry {
  final String version;
  final DateTime date;
  final List<String> highlights;
  final String notes;

  AppChangeEntry({
    required this.version,
    required this.date,
    required this.highlights,
    required this.notes,
  });

  factory AppChangeEntry.fromMap(Map<String, dynamic> map) {
    return AppChangeEntry(
      version: map['version'] as String? ?? '',
      date: DateTime.parse(map['date'] as String? ?? DateTime.now().toIso8601String()),
      highlights: List<String>.from(map['highlights'] ?? []),
      notes: map['notes'] as String? ?? '',
    );
  }
}
