import 'package:flutter_test/flutter_test.dart';
import 'package:clearsky_photo_reports/src/core/models/inspected_structure.dart';
import 'package:clearsky_photo_reports/src/core/models/saved_report.dart'
    show SavedReport, ReportPhotoEntry;
import 'package:clearsky_photo_reports/src/core/utils/summary_utils.dart';
import '../../firebase_test_setup.dart';

void main() {
  setUpAll(() async {
    await setupFirebase();
  });
  test('section summaries include damage types', () {
    final report = SavedReport(
      inspectionMetadata: {
        'clientName': 'C',
        'propertyAddress': 'A',
        'inspectionDate': DateTime(2020, 1, 1).toIso8601String(),
      },
      structures: [
        InspectedStructure(name: 'Main', sectionPhotos: {
          'Front': [
            ReportPhotoEntry(
                label: 'Front',
                photoUrl: 'p',
                damageType: 'Hail',
                timestamp: DateTime.now()),
          ],
        })
      ],
    );
    final summaries = generateSectionSummaries(report);
    expect(summaries.length, 1);
    final text = summaries.values.first;
    expect(text.contains('Hail'), isTrue);
  });
}
