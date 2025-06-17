import "package:cloud_firestore/cloud_firestore.dart";
class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      role: map['role'] ?? 'assistant',
      text: map['text'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'role': role,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };
}
