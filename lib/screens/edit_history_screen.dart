import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/ai_feedback_entry.dart';
import '../services/ai_feedback_service.dart';

class EditHistoryScreen extends StatelessWidget {
  const EditHistoryScreen({super.key});

  Future<List<AiFeedbackEntry>> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    return AiFeedbackService.instance.fetchFeedback(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit History')),
      body: FutureBuilder<List<AiFeedbackEntry>>(
        future: _load(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data!;
          if (entries.isEmpty) {
            return const Center(child: Text('No edits recorded'));
          }
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final e = entries[index];
              final ts = e.timestamp.toLocal().toString().split(' ').first;
              return ListTile(
                title: Text(e.correctedText),
                subtitle: Text('${e.type} edited on $ts'),
              );
            },
          );
        },
      ),
    );
  }
}
