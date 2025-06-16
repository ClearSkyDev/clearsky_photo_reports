class ReportMessage {
  final String id;
  final String senderId;
  final String text;
  final String? attachmentUrl;
  final DateTime createdAt;
  final List<String> readBy;

  ReportMessage({
    this.id = '',
    required this.senderId,
    required this.text,
    this.attachmentUrl,
    DateTime? createdAt,
    this.readBy = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'createdAt': createdAt.millisecondsSinceEpoch,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (readBy.isNotEmpty) 'readBy': readBy,
    };
  }

  factory ReportMessage.fromMap(Map<String, dynamic> map, String id) {
    return ReportMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      attachmentUrl: map['attachmentUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      readBy:
          map['readBy'] != null ? List<String>.from(map['readBy']) : <String>[],
    );
  }
}
