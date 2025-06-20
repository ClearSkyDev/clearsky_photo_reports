/// Types of perils an insurance claim may cover.
enum PerilType {
  wind,
  hail,
  fire,
  flood,
}

extension PerilTypeDisplay on PerilType {
  String get displayName {
    switch (this) {
      case PerilType.wind:
        return 'Wind';
      case PerilType.hail:
        return 'Hail';
      case PerilType.fire:
        return 'Fire';
      case PerilType.flood:
        return 'Flood';
    }
  }
}
