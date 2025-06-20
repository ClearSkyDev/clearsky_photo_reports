class NotificationPreferences {
  final bool newMessage;
  final bool reportFinalized;
  final bool invoiceUpdate;
  final bool aiSummary;
  final bool weeklySnapshot;
  final int snapshotDay;
  final int snapshotHour;

  const NotificationPreferences({
    this.newMessage = true,
    this.reportFinalized = true,
    this.invoiceUpdate = true,
    this.aiSummary = true,
    this.weeklySnapshot = false,
    this.snapshotDay = 1,
    this.snapshotHour = 8,
  });

  NotificationPreferences copyWith({
    bool? newMessage,
    bool? reportFinalized,
    bool? invoiceUpdate,
    bool? aiSummary,
    bool? weeklySnapshot,
    int? snapshotDay,
    int? snapshotHour,
  }) {
    return NotificationPreferences(
      newMessage: newMessage ?? this.newMessage,
      reportFinalized: reportFinalized ?? this.reportFinalized,
      invoiceUpdate: invoiceUpdate ?? this.invoiceUpdate,
      aiSummary: aiSummary ?? this.aiSummary,
      weeklySnapshot: weeklySnapshot ?? this.weeklySnapshot,
      snapshotDay: snapshotDay ?? this.snapshotDay,
      snapshotHour: snapshotHour ?? this.snapshotHour,
    );
  }

  Map<String, dynamic> toMap() => {
        'newMessage': newMessage,
        'reportFinalized': reportFinalized,
        'invoiceUpdate': invoiceUpdate,
        'aiSummary': aiSummary,
        'weeklySnapshot': weeklySnapshot,
        'snapshotDay': snapshotDay,
        'snapshotHour': snapshotHour,
      };

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      newMessage: map['newMessage'] as bool? ?? true,
      reportFinalized: map['reportFinalized'] as bool? ?? true,
      invoiceUpdate: map['invoiceUpdate'] as bool? ?? true,
      aiSummary: map['aiSummary'] as bool? ?? true,
      weeklySnapshot: map['weeklySnapshot'] as bool? ?? false,
      snapshotDay: map['snapshotDay'] as int? ?? 1,
      snapshotHour: map['snapshotHour'] as int? ?? 8,
    );
  }
}
