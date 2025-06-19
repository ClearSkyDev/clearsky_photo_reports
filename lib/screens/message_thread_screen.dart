import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Message {
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isMe;

  Message({
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    required this.isMe,
  });
}

class MessageThreadScreen extends StatefulWidget {
  final String threadTitle;
  final String currentUserId;

  const MessageThreadScreen({
    Key? key,
    required this.threadTitle,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _MessageThreadScreenState createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final newMessage = Message(
      senderId: widget.currentUserId,
      senderName: 'You',
      text: text,
      timestamp: DateTime.now(),
      isMe: true,
    );

    setState(() {
      _messages.insert(0, newMessage);
    });

    _controller.clear();

    // Simulate a reply (remove or replace with real chat logic later)
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _messages.insert(
          0,
          Message(
            senderId: 'agent456',
            senderName: 'Field Adjuster',
            text: 'Got it. Thanks for the update.',
            timestamp: DateTime.now(),
            isMe: false,
          ),
        );
      });
    });
  }

  Widget _buildMessageBubble(Message message) {
    final isMine = message.isMe;
    final bubbleColor = isMine ? Colors.blueGrey : Colors.grey[300];
    final textColor = isMine ? Colors.white : Colors.black87;
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final margin = isMine
        ? const EdgeInsets.only(left: 40, right: 8)
        : const EdgeInsets.only(right: 40, left: 8);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: margin,
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.text,
              style: TextStyle(color: textColor, fontSize: 15),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('h:mm a').format(message.timestamp),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration.collapsed(
                hintText: 'Type a message...',
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blueGrey),
            onPressed: _sendMessage,
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.threadTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('No messages yet.'))
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }
}
