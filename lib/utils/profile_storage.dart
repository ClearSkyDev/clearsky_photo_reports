import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/inspector_profile.dart';

class ProfileStorage {
  ProfileStorage._();
  static const String _key = 'inspector_profile';

  static Future<InspectorProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return null;
    return InspectorProfile.fromMap(jsonDecode(data) as Map<String, dynamic>);
  }

  static Future<void> save(InspectorProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(profile.toMap()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
