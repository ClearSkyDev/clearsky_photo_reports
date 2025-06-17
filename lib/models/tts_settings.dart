class TtsSettings {
  final String language;
  final double rate;
  final bool handsFree;
  final String voice;
  final String brandingMessage;

  const TtsSettings({
    this.language = 'en-US',
    this.rate = 0.5,
    this.handsFree = false,
    this.voice = '',
    this.brandingMessage = '',
  });

  TtsSettings copyWith({
    String? language,
    double? rate,
    bool? handsFree,
    String? voice,
    String? brandingMessage,
  }) {
    return TtsSettings(
      language: language ?? this.language,
      rate: rate ?? this.rate,
      handsFree: handsFree ?? this.handsFree,
      voice: voice ?? this.voice,
      brandingMessage: brandingMessage ?? this.brandingMessage,
    );
  }

  Map<String, dynamic> toMap() => {
        'language': language,
        'rate': rate,
        'handsFree': handsFree,
        'voice': voice,
        'brandingMessage': brandingMessage,
      };

  factory TtsSettings.fromMap(Map<String, dynamic> map) => TtsSettings(
        language: map['language'] ?? 'en-US',
        rate: (map['rate'] as num?)?.toDouble() ?? 0.5,
        handsFree: map['handsFree'] as bool? ?? false,
        voice: map['voice'] ?? '',
        brandingMessage: map['brandingMessage'] ?? '',
      );
}
