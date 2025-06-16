import 'inspected_structure.dart';

// Model for persisting completed reports in Firestore
class SavedReport {
  final String id;
  final String? userId;
  final Map<String, dynamic> inspectionMetadata;
  final List<InspectedStructure> structures;
  final String? summary;
  /// Paragraph summarizing the overall findings.
  final String? summaryText;
  /// Either a download URL or base64 encoded PNG of the inspector signature.
  final String? signature;
  /// Random ID used for public sharing of the report.
  final String? publicReportId;
  final DateTime createdAt;
  final bool isFinalized;

  SavedReport({
    this.id = '',
    this.userId,
    required this.inspectionMetadata,
    required this.structures,
    this.summary,
    this.summaryText,
    this.signature,
    this.publicReportId,
    DateTime? createdAt,
    this.isFinalized = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'inspectionMetadata': inspectionMetadata,
      'structures': structures.map((s) => s.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isFinalized': isFinalized,
      if (userId != null) 'userId': userId,
      if (summary != null) 'summary': summary,
      if (summaryText != null) 'summaryText': summaryText,
      if (signature != null) 'signature': signature,
      if (publicReportId != null) 'publicReportId': publicReportId,
    };
  }

  factory SavedReport.fromMap(Map<String, dynamic> map, String id) {
    final structs = <InspectedStructure>[];
    final rawStructs = map['structures'] as List<dynamic>? ?? [];
    for (final item in rawStructs) {
      structs.add(
          InspectedStructure.fromMap(Map<String, dynamic>.from(item as Map)));
    }

    return SavedReport(
      id: id,
      userId: map['userId'] as String?,
      inspectionMetadata:
          Map<String, dynamic>.from(map['inspectionMetadata'] ?? {}),
      structures: structs,
      summary: map['summary'] as String?,
      summaryText: map['summaryText'] as String?,
      signature: map['signature'] as String?,
      publicReportId: map['publicReportId'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      isFinalized: map['isFinalized'] as bool? ?? false,
    );
  }
}

class ReportPhotoEntry {
  final String label;
  final String photoUrl;
  final DateTime? timestamp;
  final double? latitude;
  final double? longitude;
  final String damageType;

  ReportPhotoEntry({
    required this.label,
    required this.photoUrl,
    this.timestamp,
    this.latitude,
    this.longitude,
    this.damageType = 'Unknown',
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'photoUrl': photoUrl,
      if (timestamp != null) 'timestamp': timestamp!.millisecondsSinceEpoch,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'damageType': damageType,
    };
  }

  factory ReportPhotoEntry.fromMap(Map<String, dynamic> map) {
    return ReportPhotoEntry(
      label: map['label'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : null,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      damageType: map['damageType'] as String? ?? 'Unknown',
    );
  }
}
