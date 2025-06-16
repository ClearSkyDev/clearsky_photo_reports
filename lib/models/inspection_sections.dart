import 'inspection_type.dart';

const List<String> kInspectionSections = [
  'Address Photo',
  'Front of House',
  'Front Elevation & Accessories',
  'Right Elevation & Accessories',
  'Back Elevation & Accessories',
  'Backyard Damages',
  'Left Elevation & Accessories',
  'Roof Edge',
  'Roof Slopes - Front',
  'Roof Slopes - Right',
  'Roof Slopes - Back',
  'Roof Slopes - Left',
];

List<String> sectionsForType(InspectionType type) {
  switch (type) {
    case InspectionType.commercialFlat:
      return [
        'Address Photo',
        'Roof Overview',
        'HVAC Units',
        'Parapet Walls',
        'Drainage',
        'Interior Leaks',
      ];
    default:
      return kInspectionSections;
  }
}
