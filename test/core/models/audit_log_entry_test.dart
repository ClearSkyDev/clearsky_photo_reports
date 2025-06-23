import 'package:clearsky_photo_reports/models/audit_log_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../firebase_test_setup.dart';

void main() {
  setUpAll(() async {
    await setupFirebase();
  });
  test('audit log entry map round trip', () {
    final entry = AuditLogEntry(
      userId: 'u1',
      action: 'test',
      targetId: 'r1',
      targetType: 'report',
      notes: 'n',
      timestamp: DateTime(2020, 1, 1),
    );
    final map = entry.toMap();
    final copy = AuditLogEntry.fromMap(map, 'id');
    expect(copy.userId, 'u1');
    expect(copy.action, 'test');
    expect(copy.targetId, 'r1');
    expect(copy.targetType, 'report');
    expect(copy.notes, 'n');
    expect(copy.timestamp, entry.timestamp);
  });
}
