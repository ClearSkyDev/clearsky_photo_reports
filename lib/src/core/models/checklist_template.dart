import 'inspection_type.dart';
import 'checklist_field_type.dart';

enum PerilType { wind, hail, fire, flood }

enum InspectorReportRole { ladderAssist, adjuster, contractor }

class ChecklistItemTemplate {
  final String title;
  final ChecklistFieldType type;
  final int requiredPhotos;
  final List<String> options;

  const ChecklistItemTemplate({
    required this.title,
    this.type = ChecklistFieldType.toggle,
    this.requiredPhotos = 0,
    this.options = const [],
  });
}

class ChecklistTemplate {
  final InspectionType roofType;
  final PerilType claimType;
  final InspectorReportRole role;
  final List<ChecklistItemTemplate> items;

  const ChecklistTemplate({
    required this.roofType,
    required this.claimType,
    required this.role,
    required this.items,
  });
}

const List<ChecklistTemplate> defaultChecklists = [
  ChecklistTemplate(
    roofType: InspectionType.residentialRoof,
    claimType: PerilType.wind,
    role: InspectorReportRole.ladderAssist,
    items: [
      ChecklistItemTemplate(title: 'Access Confirmed'),
      ChecklistItemTemplate(
          title: 'Ladder Photos',
          type: ChecklistFieldType.photo,
          requiredPhotos: 2),
      ChecklistItemTemplate(
        title: 'Roof Pitch',
        type: ChecklistFieldType.dropdown,
        options: ['4/12', '6/12', '8/12', '10/12+'],
      ),
    ],
  ),
  ChecklistTemplate(
    roofType: InspectionType.residentialRoof,
    claimType: PerilType.wind,
    role: InspectorReportRole.adjuster,
    items: [
      ChecklistItemTemplate(
        title: 'Damage Severity',
        type: ChecklistFieldType.dropdown,
        options: ['Minor', 'Moderate', 'Severe'],
      ),
      ChecklistItemTemplate(
          title: 'Adjuster Notes', type: ChecklistFieldType.text),
    ],
  ),
  ChecklistTemplate(
    roofType: InspectionType.residentialRoof,
    claimType: PerilType.wind,
    role: InspectorReportRole.contractor,
    items: [
      ChecklistItemTemplate(
        title: 'Work Completed',
        type: ChecklistFieldType.toggle,
      ),
      ChecklistItemTemplate(
        title: 'Completion Photos',
        type: ChecklistFieldType.photo,
        requiredPhotos: 3,
      ),
    ],
  ),
];
