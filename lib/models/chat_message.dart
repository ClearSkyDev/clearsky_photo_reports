class ChatMessage {
  final String id;
  final String role;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    DateTime ts;
    final raw = map['createdAt'];
    if (raw is DateTime) {
      ts = raw;
    } else if (raw is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(raw);
    } else if (raw is String) {
      ts = DateTime.tryParse(raw) ?? DateTime.now();
    } else if (raw != null && raw.toString().isNotEmpty) {
      try {
        // For Firestore Timestamp without importing the type
        ts = (raw as dynamic).toDate();
      } catch (_) {
        ts = DateTime.now();
      }
    } else {
      ts = DateTime.now();
    }

    return ChatMessage(
      id: id,
      role: map['role'] ?? 'assistant',
      text: map['text'] ?? '',
      createdAt: ts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'text': text,
      'createdAt': createdAt,
    };
  }
}
