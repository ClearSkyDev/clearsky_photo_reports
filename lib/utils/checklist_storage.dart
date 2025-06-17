import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/checklist.dart';
import '../models/checklist_field_type.dart';

class ChecklistStorage {
  ChecklistStorage._();
  static const String _key = 'inspection_checklist';

  static Future<void> save(InspectionChecklist checklist) async {
    final prefs = await SharedPreferences.getInstance();
    final list = checklist.steps
        .map((s) => {
              'title': s.title,
              'type': s.type.name,
              'requiredPhotos': s.requiredPhotos,
              'photosTaken': s.photosTaken,
              'isComplete': s.isComplete,
              'textValue': s.textValue,
              'dropdownValue': s.dropdownValue,
              'toggleValue': s.toggleValue,
              'options': s.options,
            })
        .toList();
    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<void> load(InspectionChecklist checklist) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return;
    final list = jsonDecode(data) as List<dynamic>;
    checklist.steps
      ..clear()
      ..addAll(list.map((e) {
        final map = Map<String, dynamic>.from(e);
        return ChecklistStep(
          title: map['title'] ?? '',
          type: ChecklistFieldType.values.firstWhere(
              (t) => t.name == map['type'],
              orElse: () => ChecklistFieldType.toggle),
          requiredPhotos: map['requiredPhotos'] ?? 0,
          photosTaken: map['photosTaken'] ?? 0,
          isComplete: map['isComplete'] ?? false,
          textValue: map['textValue'] ?? '',
          dropdownValue: map['dropdownValue'] ?? '',
          toggleValue: map['toggleValue'] ?? false,
          options: List<String>.from(map['options'] ?? const []),
        );
      }));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
