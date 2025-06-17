class Partner {
  final String id;
  final String name;
  final String code;
  final String email;

  Partner({required this.id, required this.name, required this.code, required this.email});

  factory Partner.fromMap(String id, Map<String, dynamic> map) {
    return Partner(
      id: id,
      name: map['name'] ?? '',
      code: map['code'] ?? '',
      email: map['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'email': email,
    };
  }
}
