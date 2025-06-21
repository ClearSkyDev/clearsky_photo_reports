class PendingPhoto {
  final String id;
  final String inspectionId;
  final String path;
  final String name;

  PendingPhoto({
    this.id = '',
    required this.inspectionId,
    required this.path,
    required this.name,
  });

  Map<String, dynamic> toMap() => {
        'inspectionId': inspectionId,
        'path': path,
        'name': name,
      };

  factory PendingPhoto.fromMap(Map<String, dynamic> map, String id) {
    return PendingPhoto(
      id: id,
      inspectionId: map['inspectionId'] as String? ?? '',
      path: map['path'] as String? ?? '',
      name: map['name'] as String? ?? '',
    );
  }
}
