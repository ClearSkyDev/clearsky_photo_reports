import 'package:shared_preferences/shared_preferences.dart';

class SyncPreferences {
  SyncPreferences._();
  static const String _key = 'cloud_sync_enabled';

  static Future<bool> isCloudSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  static Future<void> setCloudSyncEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
