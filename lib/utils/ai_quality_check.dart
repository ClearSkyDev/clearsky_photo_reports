import '../models/saved_report.dart';
import '../models/photo_entry.dart';
import '../models/inspection_metadata.dart';
import '../utils/photo_prompts.dart';
import '../utils/label_suggestion.dart';
import 'photo_audit.dart';

/// Runs an extended AI-powered quality check on [report].
///
/// This builds on [photoAudit] by flagging missing sections and
/// providing label or caption suggestions when absent.
Future<PhotoAuditResult> aiQualityCheck(SavedReport report) async {
  final base = await photoAudit(report);
  final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
  final issues = <PhotoAuditIssue>[];

  // Start with issues from the basic audit and add suggestions.
  for (final issue in base.issues) {
    if ((issue.issue == 'Missing label' || issue.issue == 'Missing caption') &&
        issue.photo.photoUrl.isNotEmpty) {
      try {
        final suggestion = await getLabelSuggestion(
          PhotoEntry(
            url: issue.photo.photoUrl,
            label: issue.photo.label,
            caption: issue.photo.caption,
            capturedAt: issue.photo.timestamp,
            latitude: issue.photo.latitude,
            longitude: issue.photo.longitude,
            note: issue.photo.note,
            sourceType: issue.photo.sourceType,
            captureDevice: issue.photo.captureDevice,
          ),
          issue.section,
          meta,
        );
        issues.add(PhotoAuditIssue(
          structure: issue.structure,
          section: issue.section,
          issue: issue.issue,
          photo: issue.photo,
          suggestion: issue.issue == 'Missing label'
              ? suggestion.label
              : suggestion.caption,
        ));
      } catch (_) {
        issues.add(issue);
      }
    } else {
      issues.add(issue);
    }
  }

  // Detect missing required sections based on inspection role.
  for (final struct in report.structures) {
    final map = <String, List<PhotoEntry>>{};
    for (final e in struct.sectionPhotos.entries) {
      map[e.key] = e.value
          .map((p) => PhotoEntry(
                url: p.photoUrl,
                label: p.label,
                caption: p.caption,
                capturedAt: p.timestamp,
                latitude: p.latitude,
                longitude: p.longitude,
                note: p.note,
                sourceType: p.sourceType,
                captureDevice: p.captureDevice,
              ))
          .toList();
    }
    final missing = missingSections(meta.inspectorRole, map);
    for (final section in missing) {
      issues.add(PhotoAuditIssue(
        structure: struct.name,
        section: section,
        issue: 'Missing required photos',
        photo: ReportPhotoEntry(
          label: '',
          caption: '',
          confidence: 0,
          photoUrl: '',
          timestamp: null,
        ),
      ));
    }
  }

  return PhotoAuditResult(passed: issues.isEmpty, issues: issues);
}
