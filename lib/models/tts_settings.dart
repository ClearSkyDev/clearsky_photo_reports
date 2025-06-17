class TtsSettings {
  final String language;
  final double rate;
  final bool handsFree;

  const TtsSettings({
    this.language = 'en-US',
    this.rate = 0.5,
    this.handsFree = false,
  });

  TtsSettings copyWith({String? language, double? rate, bool? handsFree}) {
    return TtsSettings(
      language: language ?? this.language,
      rate: rate ?? this.rate,
      handsFree: handsFree ?? this.handsFree,
    );
  }

  Map<String, dynamic> toMap() =>
      {'language': language, 'rate': rate, 'handsFree': handsFree};

  factory TtsSettings.fromMap(Map<String, dynamic> map) => TtsSettings(
        language: map['language'] ?? 'en-US',
        rate: (map['rate'] as num?)?.toDouble() ?? 0.5,
        handsFree: map['handsFree'] as bool? ?? false,
      );
}
