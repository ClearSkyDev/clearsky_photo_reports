import 'package:flutter_test/flutter_test.dart';
import 'package:clearsky_photo_reports/models/ai_feedback_entry.dart';
import '../../firebase_test_setup.dart';

void main() {
  setUpAll(() async {
    await setupFirebase();
  });
  test('ai feedback map round trip', () {
    final entry = AiFeedbackEntry(
      userId: 'u',
      type: 'caption',
      originalText: 'orig',
      correctedText: 'new',
      reportId: 'r1',
      targetId: 'p1',
      reason: 'typo',
      timestamp: DateTime(2021, 1, 1),
    );
    final map = entry.toMap();
    final copy = AiFeedbackEntry.fromMap(map, 'id');
    expect(copy.userId, 'u');
    expect(copy.type, 'caption');
    expect(copy.originalText, 'orig');
    expect(copy.correctedText, 'new');
    expect(copy.reportId, 'r1');
    expect(copy.targetId, 'p1');
    expect(copy.reason, 'typo');
    expect(copy.timestamp, entry.timestamp);
  });
}
