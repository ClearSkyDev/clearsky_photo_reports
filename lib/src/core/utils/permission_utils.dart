import '../models/report_collaborator.dart';
import '../models/saved_report.dart';
import '../models/inspector_profile.dart';

CollaboratorRole? roleForUser(SavedReport report, String userId) {
  for (final c in report.collaborators) {
    if (c.id == userId) return c.role;
  }
  return null;
}

bool canEditReport(SavedReport report, InspectorProfile? user) {
  if (user == null) return false;
  if (report.reportOwner == user.id) return true;
  final role = roleForUser(report, user.id);
  return role == CollaboratorRole.editor || role == CollaboratorRole.lead;
}
