import 'package:flutter_test/flutter_test.dart';
import 'package:clearsky_photo_reports/models/saved_report.dart';

void main() {
  test('saved report version round trip', () {
    final report = SavedReport(
      id: 'r1',
      version: 3,
      inspectionMetadata: const {},
      structures: const [],
      wasOffline: true,
    );
    final map = report.toMap();
    final copy = SavedReport.fromMap(map, report.id);
    expect(copy.version, 3);
    expect(copy.id, 'r1');
    expect(copy.wasOffline, isTrue);
  });
}
