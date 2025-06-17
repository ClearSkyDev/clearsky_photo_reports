import 'package:flutter_test/flutter_test.dart';
import 'package:clearsky_photo_reports/models/inspected_structure.dart';
import 'package:clearsky_photo_reports/models/saved_report.dart';
import 'package:clearsky_photo_reports/utils/summary_utils.dart';

void main() {
  test('section summaries include damage types', () {
    final report = SavedReport(
      inspectionMetadata: {
        'clientName': 'C',
        'propertyAddress': 'A',
        'inspectionDate': DateTime(2020,1,1).toIso8601String(),
      },
      structures: [
        InspectedStructure(name: 'Main', sectionPhotos: {
          'Front': [
            ReportPhotoEntry(label: 'Front', photoUrl: 'p', damageType: 'Hail', timestamp: DateTime.now()),
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
