import 'package:hive/hive.dart';

part 'local_inspection.g.dart';

@HiveType(typeId: 0)
class LocalInspection {
  @HiveField(0)
  String inspectionId;

  @HiveField(1)
  Map<String, dynamic> metadata;

  @HiveField(2)
  List<Map<String, dynamic>> photos;

  @HiveField(3)
  bool isSynced;

  LocalInspection({
    required this.inspectionId,
    required this.metadata,
    required this.photos,
    this.isSynced = false,
  });

  /// Persists this inspection to the local Hive box.
  void save() =>
      Hive.box<LocalInspection>('inspections').put(inspectionId, this);

  Map<String, dynamic> toMap() {
    return {
      'inspectionId': inspectionId,
      'metadata': metadata,
      'photos': photos,
      'isSynced': isSynced,
    };
  }

  factory LocalInspection.fromMap(Map<String, dynamic> map) {
    return LocalInspection(
      inspectionId: map['inspectionId'] as String? ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
      photos: (map['photos'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [],
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }
}
