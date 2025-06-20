import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';

/// Simple OpenAI chat client for on-site assistant.
class AiChatService {
  final String apiKey;
  final String apiUrl;

  AiChatService(
      {required this.apiKey,
      this.apiUrl = 'https://api.openai.com/v1/chat/completions'});

  Future<ChatMessage> sendMessage(
      {required String reportId,
      required String message,
      Map<String, dynamic>? context}) async {
    debugPrint('[AiChatService] sendMessage to $reportId');
    final history = await loadMessages(reportId);
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': 'You are a helpful roof inspection assistant.'
      },
      if (context != null) {'role': 'system', 'content': jsonEncode(context)},
      for (final h in history) {'role': h.role, 'content': h.text},
      {'role': 'user', 'content': message},
    ];

    final res = await http.post(Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': messages,
          'max_tokens': 200,
        }));

    if (res.statusCode != 200) {
      throw Exception('Failed to chat (${res.statusCode})');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final content = data['choices'][0]['message']['content'] as String? ?? '';
    final reply = ChatMessage(
      id: '',
      role: 'assistant',
      text: content.trim(),
      createdAt: DateTime.now(),
    );
    await _storeMessage(
        reportId,
        ChatMessage(
            id: '', role: 'user', text: message, createdAt: DateTime.now()));
    await _storeMessage(reportId, reply);
    debugPrint('[AiChatService] reply length ${reply.text.length}');
    return reply;
  }

  Future<void> _storeMessage(String reportId, ChatMessage msg) async {
    debugPrint('[AiChatService] storeMessage $reportId role=${msg.role}');
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .collection('chats')
        .add({
      'role': msg.role,
      'text': msg.text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<ChatMessage>> loadMessages(String reportId) async {
    debugPrint('[AiChatService] loadMessages $reportId');
    final snap = await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .collection('chats')
        .orderBy('createdAt')
        .get();
    return snap.docs
        .map<ChatMessage>((d) => ChatMessage.fromMap(d.data(), d.id))
        .toList();
  }
}
