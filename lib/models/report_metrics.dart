class ReportMetrics {
  final String id;
  final String inspectorId;
  final DateTime createdAt;
  final DateTime? finalizedAt;
  final int photoCount;
  final String status; // draft or finalized
  final String? zipCode;

  ReportMetrics({
    required this.id,
    required this.inspectorId,
    required this.createdAt,
    this.finalizedAt,
    required this.photoCount,
    required this.status,
    this.zipCode,
  });

  Map<String, dynamic> toMap() => {
        'inspectorId': inspectorId,
        'createdAt': createdAt.millisecondsSinceEpoch,
        if (finalizedAt != null)
          'finalizedAt': finalizedAt!.millisecondsSinceEpoch,
        'photoCount': photoCount,
        'status': status,
        if (zipCode != null) 'zipCode': zipCode,
      };

  factory ReportMetrics.fromMap(String id, Map<String, dynamic> map) {
    return ReportMetrics(
      id: id,
      inspectorId: map['inspectorId'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      finalizedAt: map['finalizedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['finalizedAt'])
          : null,
      photoCount: map['photoCount'] as int? ?? 0,
      status: map['status'] as String? ?? 'draft',
      zipCode: map['zipCode'] as String?,
    );
  }
}
