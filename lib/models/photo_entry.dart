class PhotoEntry {
  final String url;
  String label;
  bool labelLoading;

  PhotoEntry({
    required this.url,
    this.label = 'Unlabeled',
    this.labelLoading = false,
  });
}
