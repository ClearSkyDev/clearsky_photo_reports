enum SourceType { camera, drone, thermal }

class PhotoEntry {
  String url;
  String? originalUrl;
  String label;
  String caption;
  double confidence;
  double labelConfidence;
  String? labelReason;
  bool labelLoading;
  String damageType;
  bool damageLoading;
  String note;
  String? voicePath;
  String? transcript;
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
    this.caption = '',
    this.confidence = 0,
    this.labelConfidence = 0,
    this.labelReason,
    this.labelLoading = false,
    this.damageType = 'Unknown',
    this.damageLoading = false,
    this.note = '',
    this.voicePath,
    this.transcript,
    this.sourceType = SourceType.camera,
    this.captureDevice,
  }) : capturedAt = capturedAt ?? DateTime.now();
}
