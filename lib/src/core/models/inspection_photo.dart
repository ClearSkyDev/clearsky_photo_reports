import "package:image_picker/image_picker.dart";

class InspectionPhoto {
  final String imagePath;
  final String section;
  final List<String> tags;
  final DateTime timestamp;

  InspectionPhoto({
    required this.imagePath,
    required this.section,
    required this.tags,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'imagePath': imagePath,
      'section': section,
      'tags': tags,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory InspectionPhoto.fromMap(Map<String, dynamic> map) {
    return InspectionPhoto(
      imagePath: map['imagePath'] as String? ?? '',
      section: map['section'] as String? ?? '',
      tags: (map['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}

/// In-memory store of captured photos for the current inspection.
final List<InspectionPhoto> inspectionPhotos = [];

void savePhotoWithInheritedTags(
  XFile photo,
  String section,
  List<String> tags,
) {
  final newPhoto = InspectionPhoto(
    imagePath: photo.path,
    section: section,
    tags: tags,
    timestamp: DateTime.now(),
  );

  inspectionPhotos.add(newPhoto);
}
