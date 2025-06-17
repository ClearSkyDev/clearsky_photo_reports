class AuditLogEntry {
  final String id;
  final String userId;
  final String action;
  final String? targetId;
  final String? targetType;
  final String? notes;
  final DateTime timestamp;

  AuditLogEntry({
    this.id = '',
    required this.userId,
    required this.action,
    this.targetId,
    this.targetType,
    this.notes,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'action': action,
      if (targetId != null) 'targetId': targetId,
      if (targetType != null) 'targetType': targetType,
      if (notes != null) 'notes': notes,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory AuditLogEntry.fromMap(Map<String, dynamic> map, String id) {
    return AuditLogEntry(
      id: id,
      userId: map['userId'] as String? ?? '',
      action: map['action'] as String? ?? '',
      targetId: map['targetId'] as String?,
      targetType: map['targetType'] as String?,
      notes: map['notes'] as String?,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
    );
  }
}
