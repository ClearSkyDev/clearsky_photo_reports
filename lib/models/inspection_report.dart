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

  // Convert to Map (for local storage or cloud sync)
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

  // Create from Map (for local or cloud retrieval)
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
