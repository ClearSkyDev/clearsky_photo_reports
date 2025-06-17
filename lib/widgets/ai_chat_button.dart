import 'package:flutter/material.dart';

import 'ai_chat_drawer.dart';

/// Floating action button to launch the AI assistant drawer.
class AiChatButton extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic>? context;
  final String apiKey;
  const AiChatButton({super.key, required this.reportId, required this.apiKey, this.context});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      icon: const Icon(Icons.chat_bubble_outline),
      label: const Text('Ask AI'),
      onPressed: () => Scaffold.of(context).openEndDrawer(),
    );
  }
}

/// Convenience widget to wrap a Scaffold with the AI drawer.
class AiChatScaffold extends StatelessWidget {
  final Widget child;
  final String reportId;
  final Map<String, dynamic>? chatContext;
  final String apiKey;
  const AiChatScaffold({super.key, required this.child, required this.reportId, required this.apiKey, this.chatContext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: AiChatDrawer(reportId: reportId, apiKey: apiKey, context: chatContext),
      floatingActionButton: Builder(builder: (context) => AiChatButton(reportId: reportId, apiKey: apiKey, context: chatContext)),
      body: child,
    );
  }
}
