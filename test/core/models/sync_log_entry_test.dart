import 'package:flutter_test/flutter_test.dart';
import 'package:clearsky_photo_reports/models/sync_log_entry.dart';
import '../../firebase_test_setup.dart';

void main() {
  setUpAll(() async {
    await setupFirebase();
  });
  test('sync log map round trip', () {
    final entry = SyncLogEntry(
      reportId: 'r1',
      success: true,
      message: 'ok',
      timestamp: DateTime(2020, 1, 1),
    );
    final map = entry.toMap();
    final copy = SyncLogEntry.fromMap(map, 'id');
    expect(copy.reportId, 'r1');
    expect(copy.success, true);
    expect(copy.message, 'ok');
    expect(copy.timestamp, entry.timestamp);
  });
}
