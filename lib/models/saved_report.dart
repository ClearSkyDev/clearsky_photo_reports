// Model for persisting completed reports in Firestore
class SavedReport {
  final String id;
  final String? userId;
  final Map<String, dynamic> inspectionMetadata;
  final Map<String, List<ReportPhotoEntry>> sectionPhotos;
  final String? summary;
  /// Either a download URL or base64 encoded PNG of the inspector signature.
  final String? signature;
  final DateTime createdAt;

  SavedReport({
    this.id = '',
    this.userId,
    required this.inspectionMetadata,
    required this.sectionPhotos,
    this.summary,
    this.signature,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'inspectionMetadata': inspectionMetadata,
      'sectionPhotos': {
        for (var entry in sectionPhotos.entries)
          entry.key: entry.value.map((p) => p.toMap()).toList(),
      },
      'createdAt': createdAt.millisecondsSinceEpoch,
      if (userId != null) 'userId': userId,
      if (summary != null) 'summary': summary,
      if (signature != null) 'signature': signature,
    };
  }

  factory SavedReport.fromMap(Map<String, dynamic> map, String id) {
    final sections = <String, List<ReportPhotoEntry>>{};
    final rawSections = map['sectionPhotos'] as Map<String, dynamic>? ?? {};
    rawSections.forEach((key, value) {
      final list = (value as List<dynamic>)
          .map((item) => ReportPhotoEntry.fromMap(Map<String, dynamic>.from(item)))
          .toList();
      sections[key] = list;
    });

    return SavedReport(
      id: id,
      userId: map['userId'] as String?,
      inspectionMetadata:
          Map<String, dynamic>.from(map['inspectionMetadata'] ?? {}),
      sectionPhotos: sections,
      summary: map['summary'] as String?,
      signature: map['signature'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }
}

class ReportPhotoEntry {
  final String label;
  final String photoUrl;
  final DateTime? timestamp;
  final String damageType;

  ReportPhotoEntry({
    required this.label,
    required this.photoUrl,
    this.timestamp,
    this.damageType = 'Unknown',
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'photoUrl': photoUrl,
      if (timestamp != null) 'timestamp': timestamp!.millisecondsSinceEpoch,
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
      damageType: map['damageType'] as String? ?? 'Unknown',
    );
  }
}
