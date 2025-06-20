class AiFeedbackEntry {
  final String id;
  final String userId;
  final String type; // caption or summary
  final String originalText;
  final String correctedText;
  final String? reportId;
  final String? targetId;
  final String? reason;
  final DateTime timestamp;

  AiFeedbackEntry({
    this.id = '',
    required this.userId,
    required this.type,
    required this.originalText,
    required this.correctedText,
    this.reportId,
    this.targetId,
    this.reason,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'originalText': originalText,
      'correctedText': correctedText,
      if (reportId != null) 'reportId': reportId,
      if (targetId != null) 'targetId': targetId,
      if (reason != null) 'reason': reason,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory AiFeedbackEntry.fromMap(Map<String, dynamic> map, String id) {
    return AiFeedbackEntry(
      id: id,
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? 'caption',
      originalText: map['originalText'] as String? ?? '',
      correctedText: map['correctedText'] as String? ?? '',
      reportId: map['reportId'] as String?,
      targetId: map['targetId'] as String?,
      reason: map['reason'] as String?,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
    );
  }
}
