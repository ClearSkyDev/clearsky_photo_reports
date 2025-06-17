class ReportAttachment {
  final String name;
  final String url;
  final String tag;
  final String type; // pdf, docx, csv, url
  final DateTime uploadedAt;
  final bool isExternalUrl;

  ReportAttachment({
    required this.name,
    required this.url,
    this.tag = '',
    this.type = '',
    DateTime? uploadedAt,
    this.isExternalUrl = false,
  }) : uploadedAt = uploadedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      if (tag.isNotEmpty) 'tag': tag,
      if (type.isNotEmpty) 'type': type,
      'uploadedAt': uploadedAt.millisecondsSinceEpoch,
      if (isExternalUrl) 'isExternalUrl': true,
    };
  }

  factory ReportAttachment.fromMap(Map<String, dynamic> map) {
    return ReportAttachment(
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      tag: map['tag'] ?? '',
      type: map['type'] ?? '',
      uploadedAt: map['uploadedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['uploadedAt'])
          : DateTime.now(),
      isExternalUrl: map['isExternalUrl'] as bool? ?? false,
    );
  }
}
