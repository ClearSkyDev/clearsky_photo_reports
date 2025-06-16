class PhotoEntry {
  final String url;
  String label;
  bool labelLoading;
  String damageType;
  bool damageLoading;
  String note;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;

  PhotoEntry({
    required this.url,
    DateTime? capturedAt,
    this.latitude,
    this.longitude,
    this.label = 'Unlabeled',
    this.labelLoading = false,
    this.damageType = 'Unknown',
    this.damageLoading = false,
    this.note = '',
  }) : capturedAt = capturedAt ?? DateTime.now();
}
