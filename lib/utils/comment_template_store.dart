import 'package:shared_preferences/shared_preferences.dart';

class CommentTemplateStore {
  static const String _key = 'comment_templates';

  static Future<List<String>> loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> saveTemplates(List<String> templates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, templates);
  }
}
