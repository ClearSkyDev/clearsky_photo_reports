import 'saved_report.dart' show ReportPhotoEntry;
import 'interior_room.dart';

class InspectedStructure {
  final String name;
  final String? address;
  final Map<String, List<ReportPhotoEntry>> sectionPhotos;
  final Map<String, bool> slopeTestSquare;
  final List<InteriorRoom> interiorRooms;

  InspectedStructure({
    required this.name,
    this.address,
    required this.sectionPhotos,
    Map<String, bool>? slopeTestSquare,
    this.interiorRooms = const [],
  }) : slopeTestSquare = slopeTestSquare ?? const {};

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (address != null) 'address': address,
      'sectionPhotos': {
        for (var entry in sectionPhotos.entries)
          entry.key: entry.value.map((p) => p.toMap()).toList(),
      },
      if (slopeTestSquare.isNotEmpty) 'slopeTestSquare': slopeTestSquare,
      if (interiorRooms.isNotEmpty)
        'interiorRooms': interiorRooms.map((r) => r.toMap()).toList(),
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
    final rooms = (map['interiorRooms'] as List?)
            ?.map((e) =>
                InteriorRoom.fromMap(Map<String, dynamic>.from(e)))
            .toList() ??
        [];
    final slopeFlags = Map<String, bool>.from(map['slopeTestSquare'] ?? {});
    return InspectedStructure(
      name: map['name'] as String? ?? '',
      address: map['address'] as String?,
      sectionPhotos: sections,
      slopeTestSquare: slopeFlags,
      interiorRooms: rooms,
    );
  }
}
