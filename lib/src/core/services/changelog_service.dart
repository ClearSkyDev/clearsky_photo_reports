import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_changelog.dart';

class ChangelogService {
  ChangelogService._();
  static final ChangelogService instance = ChangelogService._();

  static const _seenKey = 'last_seen_version';

  List<AppChangeEntry> _entries = [];

  Future<void> init() async {
    final data = await rootBundle.loadString('assets/changelog.json');
    final List list = jsonDecode(data) as List;
    _entries = list
        .map((e) => AppChangeEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  List<AppChangeEntry> get entries => List.unmodifiable(_entries);

  AppChangeEntry? get latest => _entries.isNotEmpty ? _entries.first : null;

  Future<bool> shouldShowChangelog() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_seenKey);
    final latestVersion = latest?.version;
    return latestVersion != null && latestVersion != last;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final v = latest?.version;
    if (v != null) await prefs.setString(_seenKey, v);
  }
}
