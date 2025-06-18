class ReportMetrics {
  final String reportId;
  final int totalPhotos;
  final int annotatedPhotos;
  final int labeledPhotos;
  final int autoLabeledPhotos;
  final int customLabeledPhotos;
  final int checklistItemsCompleted;
  final Duration inspectionDuration;
  final bool wasOffline;
  final bool exportedToPdf;
  final bool exportedToHtml;
  final DateTime createdAt;
  final DateTime lastUpdated;

  ReportMetrics({
    required this.reportId,
    required this.totalPhotos,
    required this.annotatedPhotos,
    required this.labeledPhotos,
    required this.autoLabeledPhotos,
    required this.customLabeledPhotos,
    required this.checklistItemsCompleted,
    required this.inspectionDuration,
    required this.wasOffline,
    required this.exportedToPdf,
    required this.exportedToHtml,
    required this.createdAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'reportId': reportId,
      'totalPhotos': totalPhotos,
      'annotatedPhotos': annotatedPhotos,
      'labeledPhotos': labeledPhotos,
      'autoLabeledPhotos': autoLabeledPhotos,
      'customLabeledPhotos': customLabeledPhotos,
      'checklistItemsCompleted': checklistItemsCompleted,
      'inspectionDuration': inspectionDuration.inSeconds,
      'wasOffline': wasOffline,
      'exportedToPdf': exportedToPdf,
      'exportedToHtml': exportedToHtml,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory ReportMetrics.fromMap(Map<String, dynamic> map) {
    return ReportMetrics(
      reportId: map['reportId'],
      totalPhotos: map['totalPhotos'] ?? 0,
      annotatedPhotos: map['annotatedPhotos'] ?? 0,
      labeledPhotos: map['labeledPhotos'] ?? 0,
      autoLabeledPhotos: map['autoLabeledPhotos'] ?? 0,
      customLabeledPhotos: map['customLabeledPhotos'] ?? 0,
      checklistItemsCompleted: map['checklistItemsCompleted'] ?? 0,
      inspectionDuration: Duration(seconds: map['inspectionDuration'] ?? 0),
      wasOffline: map['wasOffline'] ?? false,
      exportedToPdf: map['exportedToPdf'] ?? false,
      exportedToHtml: map['exportedToHtml'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      lastUpdated: DateTime.parse(map['lastUpdated']),
    );
  }
}
