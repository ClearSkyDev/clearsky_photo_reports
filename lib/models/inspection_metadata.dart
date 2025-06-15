class InspectionMetadata {
  final String clientName;
  final String propertyAddress;
  final DateTime inspectionDate;
  final String? insuranceCarrier;
  final PerilType perilType;
  final String? inspectorName;

  InspectionMetadata({
    required this.clientName,
    required this.propertyAddress,
    required this.inspectionDate,
    this.insuranceCarrier,
    required this.perilType,
    this.inspectorName,
  });
}

enum PerilType { wind, hail, fire, other }
