import 'package:cloud_firestore/cloud_firestore.dart';
import 'inspection_type.dart';

class InspectionMetadata {
  final String clientName;
  final String propertyAddress;
  final DateTime inspectionDate;
  final String? insuranceCarrier;
  final PerilType perilType;
  final InspectionType inspectionType;
  final String? inspectorName;
  final InspectorReportRole inspectorRole;
  final String? reportId;
  final String? weatherNotes;
  final String? lastSentTo;
  final DateTime? lastSentAt;
  final String? lastSendMethod;

  InspectionMetadata({
    required this.clientName,
    required this.propertyAddress,
    required this.inspectionDate,
    this.insuranceCarrier,
    required this.perilType,
    required this.inspectionType,
    this.inspectorName,
    this.inspectorRole = InspectorReportRole.ladder_assist,
    this.reportId,
    this.weatherNotes,
    this.lastSentTo,
    this.lastSentAt,
    this.lastSendMethod,
  });

  factory InspectionMetadata.fromMap(Map<String, dynamic> map) {
    PerilType parsePeril(String? value) {
      for (final type in PerilType.values) {
        if (type.name == value) return type;
      }
      return PerilType.wind;
    }

    InspectionType parseType(String? value) {
      for (final type in InspectionType.values) {
        if (type.name == value) return type;
      }
      return InspectionType.residentialRoof;
    }

    InspectorReportRole parseRole(String? value) {
      for (final role in InspectorReportRole.values) {
        if (role.name == value) return role;
      }
      return InspectorReportRole.ladder_assist;
    }

    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return InspectionMetadata(
      clientName: map['clientName'] ?? '',
      propertyAddress: map['propertyAddress'] ?? '',
      inspectionDate: map['inspectionDate'] is Timestamp
          ? (map['inspectionDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['inspectionDate'] ?? '') ?? DateTime.now(),
      insuranceCarrier: map['insuranceCarrier'] as String?,
      perilType: parsePeril(map['perilType'] as String?),
      inspectionType: parseType(map['inspectionType'] as String?),
      inspectorName: map['inspectorName'] as String?,
      inspectorRole: parseRole(map['inspectorRole'] as String?),
      reportId: map['reportId'] as String?,
      weatherNotes: map['weatherNotes'] as String?,
      lastSentTo: map['lastSentTo'] as String?,
      lastSentAt: parseDate(map['lastSentAt']),
      lastSendMethod: map['lastSendMethod'] as String?,
    );
  }
}

enum PerilType { wind, hail, fire, other }

enum InspectorReportRole { ladder_assist, adjuster, contractor }
