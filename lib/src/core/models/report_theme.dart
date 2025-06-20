class ReportTheme {
  final String name;
  final int primaryColor;
  final String fontFamily;
  final String? logoPath;

  const ReportTheme({
    required this.name,
    required this.primaryColor,
    required this.fontFamily,
    this.logoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'primaryColor': primaryColor,
      'fontFamily': fontFamily,
      if (logoPath != null) 'logoPath': logoPath,
    };
  }

  factory ReportTheme.fromMap(Map<String, dynamic> map) {
    return ReportTheme(
      name: map['name'] ?? 'Default',
      primaryColor: map['primaryColor'] is int
          ? map['primaryColor'] as int
          : int.tryParse(map['primaryColor']?.toString() ?? '') ?? 0xff2196f3,
      fontFamily: map['fontFamily'] ?? 'Arial',
      logoPath: map['logoPath'] as String?,
    );
  }

  static const defaultTheme = ReportTheme(
    name: 'Default',
    primaryColor: 0xff2196f3,
    fontFamily: 'Arial',
    logoPath: 'assets/images/clearsky_logo.png',
  );
}
