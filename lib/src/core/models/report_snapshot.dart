class ReportSnapshot {
  final DateTime timestamp;
  final Map<String, dynamic> data;

  ReportSnapshot({DateTime? timestamp, required this.data})
      : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'data': data,
    };
  }

  factory ReportSnapshot.fromMap(Map<String, dynamic> map) {
    return ReportSnapshot(
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }
}
