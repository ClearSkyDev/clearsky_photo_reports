import 'package:shared_preferences/shared_preferences.dart';

class LearningPreferences {
  LearningPreferences._();
  static const String _key = 'ai_learning_enabled';

  static Future<bool> isLearningEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  static Future<void> setLearningEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
