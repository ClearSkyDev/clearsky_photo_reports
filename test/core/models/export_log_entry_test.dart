import 'package:flutter_test/flutter_test.dart';
import 'package:clearsky_photo_reports/models/export_log_entry.dart';
import '../../firebase_test_setup.dart';

void main() {
  setUpAll(() async {
    await setupFirebase();
  });
  test('export log entry map round trip', () {
    final entry = ExportLogEntry(
      reportName: 'Test',
      type: 'pdf',
      wasOffline: true,
      timestamp: DateTime(2023, 1, 1, 12),
    );
    final map = entry.toMap();
    final copy = ExportLogEntry.fromMap(map);
    expect(copy.reportName, 'Test');
    expect(copy.type, 'pdf');
    expect(copy.wasOffline, isTrue);
    expect(copy.timestamp, entry.timestamp);
  });
}
