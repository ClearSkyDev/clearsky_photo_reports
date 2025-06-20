class ReportChange {
  final DateTime timestamp;
  final String type;
  final String target;
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;

  ReportChange({
    DateTime? timestamp,
    required this.type,
    required this.target,
    this.before = const {},
    this.after = const {},
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
      'target': target,
      if (before.isNotEmpty) 'before': before,
      if (after.isNotEmpty) 'after': after,
    };
  }

  factory ReportChange.fromMap(Map<String, dynamic> map) {
    return ReportChange(
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      type: map['type'] as String? ?? '',
      target: map['target'] as String? ?? '',
      before: Map<String, dynamic>.from(map['before'] ?? {}),
      after: Map<String, dynamic>.from(map['after'] ?? {}),
    );
  }
}
