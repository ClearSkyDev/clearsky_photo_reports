import 'package:cloud_firestore/cloud_firestore.dart';

class InspectionMetadata {
  final String id;
  final String clientName;
  final String claimNumber;
  final String projectNumber;
  final DateTime? appointmentDate;
  final DateTime? lastSynced;
  int position;

  InspectionMetadata({
    required this.id,
    required this.clientName,
    required this.claimNumber,
    required this.projectNumber,
    this.appointmentDate,
    this.lastSynced,
    this.position = 0,
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
      lastSynced: data['lastSynced'] != null
          ? (data['lastSynced'] as Timestamp).toDate()
          : null,
      position: data['position'] is int ? data['position'] as int : 0,
    );
  }
}
