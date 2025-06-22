import 'package:shared_preferences/shared_preferences.dart';

enum InspectorRole { adjuster, contractor, ladderAssist, hybrid }

class InspectorRoleService {
  InspectorRoleService._();
  static const _key = 'inspector_role';

  static Future<void> saveRole(InspectorRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, role.name);
  }

  static Future<InspectorRole> loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleName = prefs.getString(_key);
    return InspectorRole.values.firstWhere(
      (r) => r.name == roleName,
      orElse: () => InspectorRole.adjuster,
    );
  }
}
