import 'saved_report.dart' show ReportPhotoEntry;

class InteriorRoom {
  final String name;
  final String summary;
  final Map<String, bool> checklist;
  final List<ReportPhotoEntry> photos;

  const InteriorRoom({
    required this.name,
    this.summary = '',
    this.checklist = const {},
    this.photos = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (summary.isNotEmpty) 'summary': summary,
      if (checklist.isNotEmpty) 'checklist': checklist,
      'photos': photos.map((p) => p.toMap()).toList(),
    };
  }

  factory InteriorRoom.fromMap(Map<String, dynamic> map) {
    return InteriorRoom(
      name: map['name'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      checklist: Map<String, bool>.from(map['checklist'] as Map? ?? {}),
      photos: (map['photos'] as List? ?? [])
          .map((e) => ReportPhotoEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
