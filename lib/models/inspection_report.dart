/// Model representing an inspection report.
///
/// This file previously re-exported the implementation from
/// `src/core/models/inspection_report.dart`. Some build
/// environments expect a concrete file at this path, so the class
/// definition is included here directly.
class InspectionReport {
  String id;
  String? title;
  String? address;
  DateTime date;
  bool synced;
  List<String> photoPaths; // paths or URLs to photos

  InspectionReport({
    required this.id,
    this.title,
    this.address,
    DateTime? date,
    this.synced = false,
    List<String>? photoPaths,
  })  : date = date ?? DateTime.now(),
        photoPaths = photoPaths ?? [];

  /// Convert this report to a serializable [Map].
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'date': date.toIso8601String(),
      'synced': synced,
      'photoPaths': photoPaths,
    };
  }

  /// Create a report from a serialized [map].
  factory InspectionReport.fromMap(Map<String, dynamic> map) {
    return InspectionReport(
      id: map['id'],
      title: map['title'],
      address: map['address'],
      date: DateTime.tryParse(map['date']) ?? DateTime.now(),
      synced: map['synced'] ?? false,
      photoPaths: List<String>.from(map['photoPaths'] ?? []),
    );
  }
}
