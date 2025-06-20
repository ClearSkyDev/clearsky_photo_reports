import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/ai_feedback_entry.dart';

class AiFeedbackService {
  AiFeedbackService._();
  static final AiFeedbackService instance = AiFeedbackService._();

  final _collection = FirebaseFirestore.instance.collection('ai_feedback');

  Future<void> recordFeedback({
    required String type,
    required String originalText,
    required String correctedText,
    String? reportId,
    String? targetId,
    String? reason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _collection.add({
      'userId': user.uid,
      'type': type,
      'originalText': originalText,
      'correctedText': correctedText,
      if (reportId != null) 'reportId': reportId,
      if (targetId != null) 'targetId': targetId,
      if (reason != null) 'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<AiFeedbackEntry>> fetchFeedback(String userId) async {
    final snap = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs
        .map((d) => AiFeedbackEntry.fromMap(d.data(), d.id))
        .toList();
  }

  Future<void> clearHistory(String userId) async {
    final snap = await _collection.where('userId', isEqualTo: userId).get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}
