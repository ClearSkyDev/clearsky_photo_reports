import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../models/report_message.dart';
import '../services/auth_service.dart';

/// Simple chat-style message thread between client and inspector.
class MessageThreadScreen extends StatefulWidget {
  final String reportId;
  final bool inspectorView;
  const MessageThreadScreen({
    super.key,
    required this.reportId,
    this.inspectorView = false,
  });

  @override
  State<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends State<MessageThreadScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final String _currentUserId;
  bool _resolved = false;
  bool _muted = false;

  CollectionReference<Map<String, dynamic>> get _messagesCollection =>
      FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.reportId)
          .collection('messages');

  @override
  void initState() {
    super.initState();
    _currentUserId = AuthService()._auth.currentUser?.uid ?? '';
    _loadThreadStatus();
  }

  Future<void> _loadThreadStatus() async {
    final doc =
        await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).get();
    final thread = doc.data()?['thread'] as Map<String, dynamic>?;
    if (thread != null) {
      setState(() {
        _resolved = thread['resolved'] == true;
        _muted = thread['muted'] == true;
      });
    }
  }

  Future<void> _markRead(QuerySnapshot<Map<String, dynamic>> snap) async {
    for (final doc in snap.docs) {
      final data = doc.data();
      final readBy = data['readBy'] as List<dynamic>? ?? [];
      if (!readBy.contains(_currentUserId)) {
        doc.reference.update({
          'readBy': FieldValue.arrayUnion([_currentUserId])
        });
      }
    }
  }

  Future<void> _sendMessage({String? attachmentPath}) async {
    final text = _textController.text.trim();
    if (text.isEmpty && attachmentPath == null) return;
    String? url;
    if (attachmentPath != null) {
      final file = File(attachmentPath);
      final name = attachmentPath.split('/').last;
      final ref = FirebaseStorage.instance
          .ref()
          .child('reportMessages/${widget.reportId}/$name');
      final task = await ref.putFile(file);
      url = await task.ref.getDownloadURL();
    }
    final msg = ReportMessage(
      senderId: _currentUserId,
      text: text,
      attachmentUrl: url,
    );
    await _messagesCollection.add({
      ...msg.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    _textController.clear();
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 80,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      await _sendMessage(attachmentPath: result.files.single.path!);
    }
  }

  Future<void> _resolveThread() async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.reportId)
        .set({'thread': {'resolved': true}}, SetOptions(merge: true));
    setState(() => _resolved = true);
  }

  Future<void> _toggleMute() async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.reportId)
        .set({'thread': {'muted': !_muted}}, SetOptions(merge: true));
    setState(() => _muted = !_muted);
  }

  Future<void> _exportThread() async {
    final snap = await _messagesCollection.orderBy('createdAt').get();
    final buffer = StringBuffer();
    for (final doc in snap.docs) {
      final msg = ReportMessage.fromMap(doc.data(), doc.id);
      final ts = msg.createdAt.toLocal().toIso8601String();
      buffer.writeln('$ts ${msg.senderId}: ${msg.text}');
      if (msg.attachmentUrl != null) buffer.writeln(msg.attachmentUrl);
    }
    await SharePlus.instance.share(buffer.toString());
  }

  Widget _buildMessageBubble(ReportMessage msg) {
    final isMe = msg.senderId == _currentUserId;
    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMe ? Colors.blueGrey : Colors.grey.shade300;
    final textColor = isMe ? Colors.white : Colors.black87;
    final content = <Widget>[Text(msg.text, style: TextStyle(color: textColor))];
    if (msg.attachmentUrl != null) {
      final url = msg.attachmentUrl!;
      if (url.endsWith('.pdf')) {
        content.add(const SizedBox(height: 4));
        content.add(Icon(Icons.picture_as_pdf, color: textColor));
      } else {
        content.add(const SizedBox(height: 4));
        content.add(Image.network(url, width: 160, height: 160));
      }
    }
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: content),
      ),
    );
  }

  Widget _buildInput() {
    if (_resolved) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Thread resolved'),
      );
    }
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.attach_file),
          tooltip: 'Attach File',
          onPressed: _pickAttachment,
        ),
        Expanded(
          child: TextField(
            controller: _textController,
            decoration: const InputDecoration(hintText: 'Message'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          tooltip: 'Send Message',
          onPressed: _sendMessage,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: widget.inspectorView
            ? [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'resolve') _resolveThread();
                    if (value == 'export') _exportThread();
                    if (value == 'mute') _toggleMute();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'resolve',
                      child: Text(_resolved ? 'Resolved' : 'Resolve'),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Text('Export'),
                    ),
                    PopupMenuItem(
                      value: 'mute',
                      child: Text(_muted ? 'Unmute' : 'Mute'),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messagesCollection.orderBy('createdAt').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _markRead(snapshot.data!));
                  final msgs = snapshot.data!.docs
                      .map((d) => ReportMessage.fromMap(d.data(), d.id))
                      .toList();
                  return ListView(
                    controller: _scrollController,
                    children: [for (final m in msgs) _buildMessageBubble(m)],
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const Center(child: Text('No messages'));
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }
}
