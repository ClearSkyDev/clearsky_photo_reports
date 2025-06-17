import 'package:hive/hive.dart';

import '../models/sync_log_entry.dart';

class SyncHistoryService {
  SyncHistoryService._();

  static final SyncHistoryService instance = SyncHistoryService._();

  static const String boxName = 'sync_history';

  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(boxName);
  }

  Future<void> addEntry(SyncLogEntry entry) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _box.put(id, entry.toMap());
  }

  List<SyncLogEntry> loadEntries() {
    final items = <SyncLogEntry>[];
    for (final key in _box.keys) {
      final map = Map<String, dynamic>.from(_box.get(key));
      items.add(SyncLogEntry.fromMap(map, key as String));
    }
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<void> clear() => _box.clear();
}
