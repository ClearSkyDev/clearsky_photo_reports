import 'package:shared_preferences/shared_preferences.dart';

class QuickReportPreferences {
  QuickReportPreferences._();
  static const String _key = 'quick_report_enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
