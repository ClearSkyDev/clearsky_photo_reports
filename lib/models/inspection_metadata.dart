import 'inspection_type.dart';
import 'checklist_template.dart' show PerilType, InspectorReportRole;

class InspectionMetadata {
  String clientName;
  String propertyAddress;
  DateTime inspectionDate;
  String? insuranceCarrier;
  PerilType perilType;
  InspectionType inspectionType;
  String? inspectorName;
  InspectorReportRole inspectorRole;
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
    required this.inspectorRole,
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
      'inspectorRole': inspectorRole.name,
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
    return InspectionMetadata(
      clientName: map['clientName'] ?? '',
      propertyAddress: map['propertyAddress'] ?? '',
      inspectionDate: DateTime.parse(map['inspectionDate']),
      insuranceCarrier: map['insuranceCarrier'],
      perilType: PerilType.values.byName(map['perilType'] ?? 'wind'),
      inspectionType:
          InspectionType.values.byName(map['inspectionType'] ?? 'residentialRoof'),
      inspectorName: map['inspectorName'],
      inspectorRole:
          InspectorReportRole.values.byName(map['inspectorRole'] ?? 'ladder_assist'),
      reportId: map['reportId'],
      weatherNotes: map['weatherNotes'],
      partnerCode: map['partnerCode'],
    );
  }
}
