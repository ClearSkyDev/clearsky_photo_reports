import 'inspection_type.dart';
import 'inspection_metadata.dart';
import 'inspection_sections.dart';

class ChecklistItemTemplate {
  final String title;
  final int requiredPhotos;
  const ChecklistItemTemplate({required this.title, this.requiredPhotos = 0});
}

class ChecklistTemplate {
  final InspectionType roofType;
  final PerilType claimType;
  final List<ChecklistItemTemplate> items;

  const ChecklistTemplate({
    required this.roofType,
    required this.claimType,
    required this.items,
  });
}

const List<ChecklistTemplate> defaultChecklists = [
  ChecklistTemplate(
    roofType: InspectionType.residentialRoof,
    claimType: PerilType.wind,
    items: [
      for (final s in kInspectionSections)
        ChecklistItemTemplate(title: s, requiredPhotos: 1),
      ChecklistItemTemplate(title: 'Metadata Saved'),
      ChecklistItemTemplate(title: 'Signature Captured'),
      ChecklistItemTemplate(title: 'Report Previewed'),
      ChecklistItemTemplate(title: 'Report Exported'),
    ],
  ),
];
