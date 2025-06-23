import 'package:flutter_test/flutter_test.dart';
import 'package:clearsky_photo_reports/src/core/models/inspection_metadata.dart';
import 'package:clearsky_photo_reports/src/core/models/inspection_type.dart';
import 'package:clearsky_photo_reports/src/core/models/peril_type.dart';
import 'package:clearsky_photo_reports/src/core/models/inspector_report_role.dart';
import '../../firebase_test_setup.dart';

void main() {
  setUpAll(() async {
    await setupFirebase();
  });
  test('external report urls round trip', () {
    final metadata = InspectionMetadata(
      clientName: 'C',
      propertyAddress: 'A',
      inspectionDate: DateTime(2024, 1, 1),
      perilType: PerilType.wind,
      inspectionType: InspectionType.residentialRoof,
      inspectorRoles: {InspectorReportRole.ladderAssist},
      externalReportUrls: ['u1', 'u2'],
    );
    final map = metadata.toMap();
    final copy = InspectionMetadata.fromMap({
      ...map,
      'inspectionDate': metadata.inspectionDate.toIso8601String(),
    });
    expect(copy.externalReportUrls, ['u1', 'u2']);
  });
}
