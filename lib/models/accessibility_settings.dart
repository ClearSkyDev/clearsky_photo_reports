class AccessibilitySettings {
  final double textScale;
  final bool highContrast;
  final bool screenReader;
  final bool reducedMotion;
  final bool haptics;

  const AccessibilitySettings({
    this.textScale = 1.0,
    this.highContrast = false,
    this.screenReader = false,
    this.reducedMotion = false,
    this.haptics = true,
  });

  AccessibilitySettings copyWith({
    double? textScale,
    bool? highContrast,
    bool? screenReader,
    bool? reducedMotion,
    bool? haptics,
  }) {
    return AccessibilitySettings(
      textScale: textScale ?? this.textScale,
      highContrast: highContrast ?? this.highContrast,
      screenReader: screenReader ?? this.screenReader,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      haptics: haptics ?? this.haptics,
    );
  }

  Map<String, dynamic> toMap() => {
        'textScale': textScale,
        'highContrast': highContrast,
        'screenReader': screenReader,
        'reducedMotion': reducedMotion,
        'haptics': haptics,
      };

  factory AccessibilitySettings.fromMap(Map<String, dynamic> map) {
    return AccessibilitySettings(
      textScale: (map['textScale'] as num?)?.toDouble() ?? 1.0,
      highContrast: map['highContrast'] as bool? ?? false,
      screenReader: map['screenReader'] as bool? ?? false,
      reducedMotion: map['reducedMotion'] as bool? ?? false,
      haptics: map['haptics'] as bool? ?? true,
    );
  }
}
