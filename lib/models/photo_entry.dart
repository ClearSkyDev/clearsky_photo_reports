class PhotoEntry {
  String url;
  String? originalUrl;
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
    this.originalUrl,
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
