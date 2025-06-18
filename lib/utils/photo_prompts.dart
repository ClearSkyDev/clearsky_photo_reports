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
  Set<InspectorReportRole> roles,
  Map<String, List<PhotoEntry>> sections,
) {
  final result = <String>{};
  for (final role in roles) {
    final req = kRequiredPhotosByRole[role];
    if (req == null) continue;
    req.forEach((section, count) {
      final taken = sections[section]?.length ?? 0;
      if (taken < count) result.add(section);
    });
  }
  return result.toList();
}

String? nextRequiredSection(
  Set<InspectorReportRole> roles,
  Map<String, List<PhotoEntry>> sections,
) {
  final missing = missingSections(roles, sections);
  return missing.isNotEmpty ? missing.first : null;
}

int remainingCount(
  Set<InspectorReportRole> roles,
  String section,
  Map<String, List<PhotoEntry>> sections,
) {
  int required = 0;
  for (final role in roles) {
    final req = kRequiredPhotosByRole[role]?[section];
    if (req != null && req > required) required = req;
  }
  final taken = sections[section]?.length ?? 0;
  final remaining = required - taken;
  return remaining > 0 ? remaining : 0;
}
