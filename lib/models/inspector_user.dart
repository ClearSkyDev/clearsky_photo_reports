enum UserRole { admin, lead, inspector, viewer, partner }

class InspectorUser {
  final String uid;
  final UserRole role;
  final String? companyId;

  InspectorUser({required this.uid, required this.role, this.companyId});

  Map<String, dynamic> toMap() => {
        'role': role.name,
        if (companyId != null) 'companyId': companyId,
      };

  factory InspectorUser.fromMap(String uid, Map<String, dynamic> map) {
    UserRole parseRole(String? value) {
      for (final r in UserRole.values) {
        if (r.name == value) return r;
      }
      return UserRole.inspector;
    }

    return InspectorUser(
      uid: uid,
      role: parseRole(map['role'] as String?),
      companyId: map['companyId'] as String?,
    );
  }
}
