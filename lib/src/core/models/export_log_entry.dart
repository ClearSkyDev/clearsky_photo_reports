class ExportLogEntry {
  final String reportName;
  final DateTime timestamp;
  final String type; // pdf or html
  final bool wasOffline;

  ExportLogEntry({
    required this.reportName,
    required this.type,
    required this.wasOffline,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'reportName': reportName,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type,
      'wasOffline': wasOffline,
    };
  }

  factory ExportLogEntry.fromMap(Map<String, dynamic> map) {
    return ExportLogEntry(
      reportName: map['reportName'] ?? '',
      type: map['type'] ?? 'pdf',
      wasOffline: map['wasOffline'] ?? false,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
    );
  }
}
