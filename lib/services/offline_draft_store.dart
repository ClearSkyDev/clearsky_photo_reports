import 'package:hive/hive.dart';
import '../models/saved_report.dart';

class OfflineDraftStore {
  OfflineDraftStore._();
  static final OfflineDraftStore instance = OfflineDraftStore._();

  static const String boxName = 'draft_reports';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(boxName);
  }

  Future<void> saveReport(SavedReport report) async {
    final id = report.id.isNotEmpty
        ? report.id
        : DateTime.now().millisecondsSinceEpoch.toString();
    final map = Map<String, dynamic>.from(report.toMap())..['localOnly'] = true;
    await _box.put(id, map);
  }

  List<SavedReport> loadReports() {
    return _box.keys.map((key) {
      final map = Map<String, dynamic>.from(_box.get(key));
      return SavedReport.fromMap(map, key as String);
    }).toList();
  }

  Future<void> delete(String id) => _box.delete(id);

  int get count => _box.length;

  Future<void> clear() => _box.clear();
}
