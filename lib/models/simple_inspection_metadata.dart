import 'package:cloud_firestore/cloud_firestore.dart';

class InspectionMetadata {
  final String id;
  final String clientName;
  final String claimNumber;
  final String projectNumber;
  final DateTime? appointmentDate;

  InspectionMetadata({
    required this.id,
    required this.clientName,
    required this.claimNumber,
    required this.projectNumber,
    this.appointmentDate,
  });

  factory InspectionMetadata.fromMap(String id, Map<String, dynamic> data) {
    return InspectionMetadata(
      id: id,
      clientName: data['clientName'] ?? '',
      claimNumber: data['claimNumber'] ?? '',
      projectNumber: data['projectNumber'] ?? '',
      appointmentDate: data['appointmentDate'] != null
          ? (data['appointmentDate'] as Timestamp).toDate()
          : null,
    );
  }
}
