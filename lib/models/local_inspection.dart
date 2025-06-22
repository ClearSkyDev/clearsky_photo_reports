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

  /// Persists this inspection in the Hive box.
  void save() =>
      Hive.box<LocalInspection>('inspections').put(inspectionId, this);
}
