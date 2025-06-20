import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/audit_log_entry.dart';

class AuditLogService {
  final _collection = FirebaseFirestore.instance.collection('adminLogs');

  Future<void> logAction(
    String action, {
    String? targetId,
    String? targetType,
    String? notes,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _collection.add({
      'userId': user.uid,
      'action': action,
      if (targetId != null) 'targetId': targetId,
      if (targetType != null) 'targetType': targetType,
      if (notes != null) 'notes': notes,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<AuditLogEntry>> fetchLogs({
    String? userId,
    String? action,
    String? targetId,
    DateTimeRange? range,
  }) async {
    Query<Map<String, dynamic>> q =
        _collection.orderBy('timestamp', descending: true);
    if (userId != null && userId.isNotEmpty) {
      q = q.where('userId', isEqualTo: userId);
    }
    if (action != null && action.isNotEmpty) {
      q = q.where('action', isEqualTo: action);
    }
    if (targetId != null && targetId.isNotEmpty) {
      q = q.where('targetId', isEqualTo: targetId);
    }
    if (range != null) {
      q = q
          .where('timestamp', isGreaterThanOrEqualTo: range.start)
          .where('timestamp', isLessThanOrEqualTo: range.end);
    }
    final snap = await q.get();
    return snap.docs.map((d) => AuditLogEntry.fromMap(d.data(), d.id)).toList();
  }
}
