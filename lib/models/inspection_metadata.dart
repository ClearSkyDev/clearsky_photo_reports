class InspectionMetadata {
  // Send metadata
  String? lastSendMethod;
  String? lastSentTo;
  DateTime? lastSentAt;

  // Start-of-inspection metadata
  DateTime? startTimestamp;
  double? startLatitude;
  double? startLongitude;

  // Inspector roles (optional)
  List<String> inspectorRoles;

  InspectionMetadata({
    this.lastSendMethod,
    this.lastSentTo,
    this.lastSentAt,
    this.startTimestamp,
    this.startLatitude,
    this.startLongitude,
    List<String>? inspectorRoles,
  }) : inspectorRoles = inspectorRoles ?? [];

  /// Convert to map (e.g., for storage or JSON)
  Map<String, dynamic> toMap() {
    return {
      'lastSendMethod': lastSendMethod,
      'lastSentTo': lastSentTo,
      'lastSentAt': lastSentAt?.toIso8601String(),
      'startTimestamp': startTimestamp?.toIso8601String(),
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'inspectorRoles': inspectorRoles,
    };
  }

  /// Construct from map (e.g., when loading saved data)
  factory InspectionMetadata.fromMap(Map<String, dynamic> map) {
    return InspectionMetadata(
      lastSendMethod: map['lastSendMethod'],
      lastSentTo: map['lastSentTo'],
      lastSentAt: map['lastSentAt'] != null
          ? DateTime.tryParse(map['lastSentAt'])
          : null,
      startTimestamp: map['startTimestamp'] != null
          ? DateTime.tryParse(map['startTimestamp'])
          : null,
      startLatitude: map['startLatitude']?.toDouble(),
      startLongitude: map['startLongitude']?.toDouble(),
      inspectorRoles: List<String>.from(map['inspectorRoles'] ?? []),
    );
  }
}
