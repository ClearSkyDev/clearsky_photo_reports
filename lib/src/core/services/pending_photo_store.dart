import 'package:hive/hive.dart';

import '../models/pending_photo.dart';

class PendingPhotoStore {
  PendingPhotoStore._();
  static final PendingPhotoStore instance = PendingPhotoStore._();

  static const String boxName = 'pending_photos';

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(boxName);
  }

  Future<void> addPhoto(PendingPhoto photo) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _box.put(id, photo.toMap());
  }

  List<PendingPhoto> loadUnsynced(String inspectionId) {
    final items = <PendingPhoto>[];
    for (final key in _box.keys) {
      final map = Map<String, dynamic>.from(_box.get(key));
      if (map['inspectionId'] == inspectionId) {
        items.add(PendingPhoto.fromMap(map, key as String));
      }
    }
    return items;
  }

  Future<void> delete(String id) => _box.delete(id);
}
