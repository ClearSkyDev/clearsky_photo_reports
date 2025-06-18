class InspectionMetadata {
  String clientName;
  String propertyAddress;
  DateTime inspectionDate;
  String inspectorName;
  String inspectorRole; // e.g., Ladder Assist, Adjuster, Contractor
  String insuranceCarrier;
  String claimNumber;
  String jobId;
  bool isFinalized;

  InspectionMetadata({
    required this.clientName,
    required this.propertyAddress,
    required this.inspectionDate,
    required this.inspectorName,
    required this.inspectorRole,
    this.insuranceCarrier = '',
    this.claimNumber = '',
    this.jobId = '',
    this.isFinalized = false,
  });

  // Convert to Map (for saving to JSON, Firestore, etc.)
  Map<String, dynamic> toMap() {
    return {
      'clientName': clientName,
      'propertyAddress': propertyAddress,
      'inspectionDate': inspectionDate.toIso8601String(),
      'inspectorName': inspectorName,
      'inspectorRole': inspectorRole,
      'insuranceCarrier': insuranceCarrier,
      'claimNumber': claimNumber,
      'jobId': jobId,
      'isFinalized': isFinalized,
    };
  }

  // Load from Map
  factory InspectionMetadata.fromMap(Map<String, dynamic> map) {
    return InspectionMetadata(
      clientName: map['clientName'] ?? '',
      propertyAddress: map['propertyAddress'] ?? '',
      inspectionDate: DateTime.parse(map['inspectionDate']),
      inspectorName: map['inspectorName'] ?? '',
      inspectorRole: map['inspectorRole'] ?? '',
      insuranceCarrier: map['insuranceCarrier'] ?? '',
      claimNumber: map['claimNumber'] ?? '',
      jobId: map['jobId'] ?? '',
      isFinalized: map['isFinalized'] ?? false,
    );
  }
}
