class PhotoEntry {
  final String url;
  String label;
  bool labelLoading;
  String damageType;
  bool damageLoading;

  PhotoEntry({
    required this.url,
    this.label = 'Unlabeled',
    this.labelLoading = false,
    this.damageType = 'Unknown',
    this.damageLoading = false,
  });
}
