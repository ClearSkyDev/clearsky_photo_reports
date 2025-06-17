import 'package:cloud_firestore/cloud_firestore.dart';

class ReportMetrics {
  final String id;
  final String inspectorId;
  final DateTime createdAt;
  final DateTime? finalizedAt;
  final int photoCount;
  final String status; // draft or finalized
  final String? zipCode;
  final String? clientName;
  final String? perilType;
  final double damagePercent;
  final double? invoiceAmount;

  ReportMetrics({
    required this.id,
    required this.inspectorId,
    required this.createdAt,
    this.finalizedAt,
    required this.photoCount,
    required this.status,
    this.zipCode,
    this.clientName,
    this.perilType,
    this.damagePercent = 0,
    this.invoiceAmount,
  });

  Map<String, dynamic> toMap() => {
        'inspectorId': inspectorId,
        'createdAt': createdAt.millisecondsSinceEpoch,
        if (finalizedAt != null)
          'finalizedAt': finalizedAt!.millisecondsSinceEpoch,
        'photoCount': photoCount,
        'status': status,
        if (zipCode != null) 'zipCode': zipCode,
        if (clientName != null) 'clientName': clientName,
        if (perilType != null) 'perilType': perilType,
        'damagePercent': damagePercent,
        if (invoiceAmount != null) 'invoiceAmount': invoiceAmount,
      };

  factory ReportMetrics.fromMap(String id, Map<String, dynamic> map) {
    return ReportMetrics(
      id: id,
      inspectorId: map['inspectorId'] as String? ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      finalizedAt: map['finalizedAt'] is Timestamp
          ? (map['finalizedAt'] as Timestamp).toDate()
          : map['finalizedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['finalizedAt'])
              : null,
      photoCount: map['photoCount'] as int? ?? 0,
      status: map['status'] as String? ?? 'draft',
      zipCode: map['zipCode'] as String?,
      clientName: map['clientName'] as String?,
      perilType: map['perilType'] as String?,
      damagePercent: (map['damagePercent'] as num?)?.toDouble() ?? 0,
      invoiceAmount: (map['invoiceAmount'] as num?)?.toDouble(),
    );
  }
}
