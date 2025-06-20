import 'inspection_type.dart';
import 'peril_type.dart';
import 'checklist_template.dart' show InspectorReportRole;

class InspectionMetadata {
  String clientName;
  String propertyAddress;
  DateTime inspectionDate;
  String? insuranceCarrier;
  PerilType perilType;
  InspectionType inspectionType;
  String? inspectorName;
  Set<InspectorReportRole> inspectorRoles;
  String? reportId;
  String? weatherNotes;
  String? partnerCode;

  InspectionMetadata({
    required this.clientName,
    required this.propertyAddress,
    required this.inspectionDate,
    this.insuranceCarrier,
    required this.perilType,
    required this.inspectionType,
    this.inspectorName,
    required this.inspectorRoles,
    this.reportId,
    this.weatherNotes,
    this.partnerCode,
  });

  // Convert to Map (for saving to JSON, Firestore, etc.)
  Map<String, dynamic> toMap() {
    return {
      'clientName': clientName,
      'propertyAddress': propertyAddress,
      'inspectionDate': inspectionDate.toIso8601String(),
      if (inspectorName != null) 'inspectorName': inspectorName,
      'inspectorRoles': inspectorRoles.map((e) => e.name).toList(),
      if (insuranceCarrier != null) 'insuranceCarrier': insuranceCarrier,
      'perilType': perilType.name,
      'inspectionType': inspectionType.name,
      if (reportId != null) 'reportId': reportId,
      if (weatherNotes != null) 'weatherNotes': weatherNotes,
      if (partnerCode != null) 'partnerCode': partnerCode,
    };
  }

  // Load from Map
  factory InspectionMetadata.fromMap(Map<String, dynamic> map) {
    final roles = (map['inspectorRoles'] as List?)
            ?.map((e) => InspectorReportRole.values.byName(e))
            .toSet() ??
        {
          InspectorReportRole.ladderAssist,
        };
    return InspectionMetadata(
      clientName: map['clientName'] ?? '',
      propertyAddress: map['propertyAddress'] ?? '',
      inspectionDate: DateTime.parse(map['inspectionDate']),
      insuranceCarrier: map['insuranceCarrier'],
      perilType: PerilType.values.byName(map['perilType'] ?? 'wind'),
      inspectionType: InspectionType.values
          .byName(map['inspectionType'] ?? 'residentialRoof'),
      inspectorName: map['inspectorName'],
      inspectorRoles: roles,
      reportId: map['reportId'],
      weatherNotes: map['weatherNotes'],
      partnerCode: map['partnerCode'],
    );
  }
}
