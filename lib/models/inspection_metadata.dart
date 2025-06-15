import 'package:cloud_firestore/cloud_firestore.dart';

class InspectionMetadata {
  final String clientName;
  final String propertyAddress;
  final DateTime inspectionDate;
  final String? insuranceCarrier;
  final PerilType perilType;
  final String? inspectorName;
  final String? reportId;
  final String? weatherNotes;

  InspectionMetadata({
    required this.clientName,
    required this.propertyAddress,
    required this.inspectionDate,
    this.insuranceCarrier,
    required this.perilType,
    this.inspectorName,
    this.reportId,
    this.weatherNotes,
  });

  factory InspectionMetadata.fromMap(Map<String, dynamic> map) {
    PerilType parsePeril(String? value) {
      for (final type in PerilType.values) {
        if (type.name == value) return type;
      }
      return PerilType.wind;
    }

    return InspectionMetadata(
      clientName: map['clientName'] ?? '',
      propertyAddress: map['propertyAddress'] ?? '',
      inspectionDate: map['inspectionDate'] is Timestamp
          ? (map['inspectionDate'] as Timestamp).toDate()
          : DateTime.tryParse(map['inspectionDate'] ?? '') ?? DateTime.now(),
      insuranceCarrier: map['insuranceCarrier'] as String?,
      perilType: parsePeril(map['perilType'] as String?),
      inspectorName: map['inspectorName'] as String?,
      reportId: map['reportId'] as String?,
      weatherNotes: map['weatherNotes'] as String?,
    );
  }
}

enum PerilType { wind, hail, fire, other }
