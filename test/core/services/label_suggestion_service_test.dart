import 'package:flutter_test/flutter_test.dart';
import 'package:clearsky_photo_reports/src/core/services/label_suggestion_service.dart';

void main() {
  group('LabelSuggestionService', () {
    test('returns front elevation suggestion', () async {
      final label = await LabelSuggestionService.suggestLabel(
        sectionPrefix: 'Front Elevation',
        photoUri: 'foo.jpg',
      );
      expect(label, contains('Front elevation'));
    });

    test('returns roof slope suggestion', () async {
      final label = await LabelSuggestionService.suggestLabel(
        sectionPrefix: 'Roof Slope East',
        photoUri: 'foo.jpg',
      );
      expect(label, contains('Roof slope'));
    });

    test('returns default suggestion', () async {
      final label = await LabelSuggestionService.suggestLabel(
        sectionPrefix: 'Unknown Section',
        photoUri: 'foo.jpg',
      );
      expect(label, contains('needs review'));
    });
  });
}
