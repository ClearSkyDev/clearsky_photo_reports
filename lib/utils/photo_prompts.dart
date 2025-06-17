import '../models/inspection_metadata.dart';
import '../models/photo_entry.dart';

/// Required photo counts for each inspection role by section.
const Map<InspectorReportRole, Map<String, int>> kRequiredPhotosByRole = {
  InspectorReportRole.ladder_assist: {
    'Front of House': 1,
    'Roof Edge': 1,
  },
  InspectorReportRole.adjuster: {
    'Front of House': 1,
    'Roof Edge': 2,
    'Backyard Damages': 3,
  },
  InspectorReportRole.contractor: {
    'Front of House': 1,
    'Roof Slopes - Front': 2,
  },
};

List<String> missingSections(
  InspectorReportRole role,
  Map<String, List<PhotoEntry>> sections,
) {
  final req = kRequiredPhotosByRole[role];
  if (req == null) return [];
  final result = <String>[];
  req.forEach((section, count) {
    final taken = sections[section]?.length ?? 0;
    if (taken < count) result.add(section);
  });
  return result;
}

String? nextRequiredSection(
  InspectorReportRole role,
  Map<String, List<PhotoEntry>> sections,
) {
  final missing = missingSections(role, sections);
  return missing.isNotEmpty ? missing.first : null;
}

int remainingCount(
  InspectorReportRole role,
  String section,
  Map<String, List<PhotoEntry>> sections,
) {
  final req = kRequiredPhotosByRole[role]?[section];
  if (req == null) return 0;
  final taken = sections[section]?.length ?? 0;
  final remaining = req - taken;
  return remaining > 0 ? remaining : 0;
}
