class HomeownerSignature {
  final String name;
  final String image;
  final DateTime timestamp;
  final bool declined;
  final String? declineReason;

  HomeownerSignature({
    required this.name,
    required this.image,
    DateTime? timestamp,
    this.declined = false,
    this.declineReason,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image': image,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'declined': declined,
      if (declineReason != null) 'declineReason': declineReason,
    };
  }

  factory HomeownerSignature.fromMap(Map<String, dynamic> map) {
    return HomeownerSignature(
      name: map['name'] ?? '',
      image: map['image'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : DateTime.now(),
      declined: map['declined'] as bool? ?? false,
      declineReason: map['declineReason'] as String?,
    );
  }
}
