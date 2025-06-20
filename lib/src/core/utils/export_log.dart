import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/export_log_entry.dart';

class ExportLog {
  ExportLog._();
  static const String _key = 'export_history';

  static Future<List<ExportLogEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    final list = jsonDecode(data) as List<dynamic>;
    return list
        .map((e) => ExportLogEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> _save(List<ExportLogEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(entries.map((e) => e.toMap()).toList()),
    );
  }

  static Future<void> addEntry(ExportLogEntry entry) async {
    final entries = await load();
    entries.insert(0, entry);
    if (entries.length > 50) {
      entries.removeRange(50, entries.length);
    }
    await _save(entries);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
