import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/report_template.dart';

/// Simple local storage for inspection templates using SharedPreferences.
class TemplateStore {
  TemplateStore._();

  static const String _key = 'report_templates';

  /// Load all saved templates. Returns an empty list if none exist.
  static Future<List<ReportTemplate>> loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    final list = jsonDecode(data) as List<dynamic>;
    return list
        .map((e) => ReportTemplate.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Persist [templates] as the current list of templates.
  static Future<void> saveTemplates(List<ReportTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(templates.map((t) => t.toMap()).toList()),
    );
  }

  /// Save or update a single [template].
  static Future<void> saveTemplate(ReportTemplate template) async {
    final templates = await loadTemplates();
    final idx = templates.indexWhere((t) => t.id == template.id);
    if (idx >= 0) {
      templates[idx] = template;
    } else {
      templates.add(template);
    }
    await saveTemplates(templates);
  }

  static Future<void> deleteTemplate(String id) async {
    final templates = await loadTemplates();
    templates.removeWhere((t) => t.id == id);
    await saveTemplates(templates);
  }
}
