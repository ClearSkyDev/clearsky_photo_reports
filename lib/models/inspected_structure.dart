import 'saved_report.dart' show ReportPhotoEntry;

class InspectedStructure {
  final String name;
  final String? address;
  final Map<String, List<ReportPhotoEntry>> sectionPhotos;

  InspectedStructure({required this.name, this.address, required this.sectionPhotos});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (address != null) 'address': address,
      'sectionPhotos': {
        for (var entry in sectionPhotos.entries)
          entry.key: entry.value.map((p) => p.toMap()).toList(),
      },
    };
  }

  factory InspectedStructure.fromMap(Map<String, dynamic> map) {
    final sections = <String, List<ReportPhotoEntry>>{};
    final raw = map['sectionPhotos'] as Map<String, dynamic>? ?? {};
    raw.forEach((key, value) {
      final list = (value as List<dynamic>)
          .map((e) => ReportPhotoEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      sections[key] = list;
    });
    return InspectedStructure(
      name: map['name'] as String? ?? '',
      address: map['address'] as String?,
      sectionPhotos: sections,
    );
  }
}
