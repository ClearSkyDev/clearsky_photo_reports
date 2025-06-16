class NotificationPreferences {
  final bool newMessage;
  final bool reportFinalized;
  final bool invoiceUpdate;
  final bool aiSummary;

  const NotificationPreferences({
    this.newMessage = true,
    this.reportFinalized = true,
    this.invoiceUpdate = true,
    this.aiSummary = true,
  });

  NotificationPreferences copyWith({
    bool? newMessage,
    bool? reportFinalized,
    bool? invoiceUpdate,
    bool? aiSummary,
  }) {
    return NotificationPreferences(
      newMessage: newMessage ?? this.newMessage,
      reportFinalized: reportFinalized ?? this.reportFinalized,
      invoiceUpdate: invoiceUpdate ?? this.invoiceUpdate,
      aiSummary: aiSummary ?? this.aiSummary,
    );
  }

  Map<String, dynamic> toMap() => {
        'newMessage': newMessage,
        'reportFinalized': reportFinalized,
        'invoiceUpdate': invoiceUpdate,
        'aiSummary': aiSummary,
      };

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      newMessage: map['newMessage'] as bool? ?? true,
      reportFinalized: map['reportFinalized'] as bool? ?? true,
      invoiceUpdate: map['invoiceUpdate'] as bool? ?? true,
      aiSummary: map['aiSummary'] as bool? ?? true,
    );
  }
}
