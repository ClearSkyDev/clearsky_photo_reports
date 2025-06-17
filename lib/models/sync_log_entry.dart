class SyncLogEntry {
  final String id;
  final String reportId;
  final DateTime timestamp;
  final bool success;
  final String message;

  SyncLogEntry({
    this.id = '',
    required this.reportId,
    required this.success,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'success': success,
      'message': message,
    };
  }

  factory SyncLogEntry.fromMap(Map<String, dynamic> map, String id) {
    return SyncLogEntry(
      id: id,
      reportId: map['reportId'] as String? ?? '',
      success: map['success'] as bool? ?? false,
      message: map['message'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
    );
  }
}
