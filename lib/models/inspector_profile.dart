enum InspectorRole { admin, inspector }

class InspectorProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? company;
  final String? signature;
  final InspectorRole role;

  InspectorProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.company,
    this.signature,
    this.role = InspectorRole.inspector,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      if (company != null) 'company': company,
      if (signature != null) 'signature': signature,
      'role': role.name,
    };
  }

  factory InspectorProfile.fromMap(Map<String, dynamic> map) {
    InspectorRole parseRole(String? value) {
      for (final r in InspectorRole.values) {
        if (r.name == value) return r;
      }
      return InspectorRole.inspector;
    }

    return InspectorProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] as String?,
      company: map['company'] as String?,
      signature: map['signature'] as String?,
      role: parseRole(map['role'] as String?),
    );
  }
}
