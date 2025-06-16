enum CollaboratorRole { viewer, editor, lead }

class ReportCollaborator {
  final String id;
  final String name;
  final CollaboratorRole role;

  ReportCollaborator({
    required this.id,
    required this.name,
    this.role = CollaboratorRole.viewer,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role.name,
    };
  }

  factory ReportCollaborator.fromMap(Map<String, dynamic> map) {
    CollaboratorRole parseRole(String? value) {
      for (final r in CollaboratorRole.values) {
        if (r.name == value) return r;
      }
      return CollaboratorRole.viewer;
    }

    return ReportCollaborator(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      role: parseRole(map['role'] as String?),
    );
  }
}
