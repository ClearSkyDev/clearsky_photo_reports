import 'package:flutter/material.dart';

import '../../core/models/chat_message.dart';
import '../../core/services/ai_chat_service.dart';
import '../../core/utils/logging.dart';

/// Sliding drawer for the on-site AI assistant.
class AiChatDrawer extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic>? context;
  final String apiKey;
  const AiChatDrawer(
      {super.key, required this.reportId, required this.apiKey, this.context});

  @override
  State<AiChatDrawer> createState() => _AiChatDrawerState();
}

class _AiChatDrawerState extends State<AiChatDrawer> {
  final TextEditingController _controller = TextEditingController();
  late final AiChatService _service;
  final List<ChatMessage> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _service = AiChatService(apiKey: widget.apiKey);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _service.loadMessages(widget.reportId);
      if (!mounted) return;
      setState(() => _messages.addAll(history));
    } catch (e) {
      logger().d('[AiChatDrawer] loadHistory error: $e');
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
          id: '', role: 'user', text: text, createdAt: DateTime.now()));
      _loading = true;
    });
    _controller.clear();
    try {
      final reply = await _service.sendMessage(
          reportId: widget.reportId, message: text, context: widget.context);
      if (!mounted) return;
      setState(() {
        _messages.add(reply);
        _loading = false;
      });
    } catch (e) {
      logger().d('[AiChatDrawer] send error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('ClearSky AI Assistant',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView(
                children: [for (final m in _messages) _buildBubble(m)],
              ),
            ),
            if (_loading) const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration:
                          const InputDecoration(hintText: 'Ask a question'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    tooltip: 'Send',
                    onPressed: _loading ? null : _send,
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isUser = msg.role == 'user';
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser ? Colors.blueGrey : Colors.grey.shade300;
    final textColor = isUser ? Colors.white : Colors.black87;
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(msg.text, style: TextStyle(color: textColor)),
      ),
    );
  }
}
