enum SourceType { camera, drone, thermal }

class PhotoEntry {
  String url;
  String? originalUrl;
  String label;
  bool labelLoading;
  String damageType;
  bool damageLoading;
  String note;
  SourceType sourceType;
  String? captureDevice;
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
    this.sourceType = SourceType.camera,
    this.captureDevice,
  }) : capturedAt = capturedAt ?? DateTime.now();
}
