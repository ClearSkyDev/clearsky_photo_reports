import 'dart:convert';

class ReportTemplate {
  final String id;
  final String name;
  final List<String> sections;
  final Map<String, String> photoPrompts;
  final Map<String, dynamic> defaultMetadata;

  const ReportTemplate({
    required this.id,
    required this.name,
    required this.sections,
    this.photoPrompts = const {},
    this.defaultMetadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sections': sections,
      if (photoPrompts.isNotEmpty) 'photoPrompts': photoPrompts,
      if (defaultMetadata.isNotEmpty) 'defaultMetadata': defaultMetadata,
    };
  }

  factory ReportTemplate.fromMap(Map<String, dynamic> map) {
    return ReportTemplate(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      sections: (map['sections'] as List<dynamic>? ?? []).cast<String>(),
      photoPrompts: Map<String, String>.from(map['photoPrompts'] ?? {}),
      defaultMetadata: Map<String, dynamic>.from(map['defaultMetadata'] ?? {}),
    );
  }

  ReportTemplate copyWith({
    String? id,
    String? name,
    List<String>? sections,
    Map<String, String>? photoPrompts,
    Map<String, dynamic>? defaultMetadata,
  }) {
    return ReportTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      sections: sections ?? this.sections,
      photoPrompts: photoPrompts ?? this.photoPrompts,
      defaultMetadata: defaultMetadata ?? this.defaultMetadata,
    );
  }

  @override
  String toString() => jsonEncode(toMap());
}
