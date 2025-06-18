import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

import '../models/saved_report.dart';
import '../models/inspection_metadata.dart';
import '../models/inspected_structure.dart';

/// Stores reports on the local device using JSON files.
///
/// Each report is written to a folder under the application's documents
/// directory. Photo files are copied into the folder so the report can be
/// reloaded later. A list of saved report IDs is tracked using
/// [SharedPreferences].
class LocalReportStore {
  LocalReportStore._();

  static final LocalReportStore instance = LocalReportStore._();

  static const String _indexKey = 'local_report_ids';

  Future<Directory> get _reportsDir async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'reports'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Saves [report] to disk and returns the stored ID.
  Future<String> saveReport(SavedReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final base = await _reportsDir;
    final id = report.id.isNotEmpty
        ? report.id
        : DateTime.now().millisecondsSinceEpoch.toString();
    final reportDir = Directory(p.join(base.path, id));
    if (!await reportDir.exists()) {
      await reportDir.create(recursive: true);
    }

    final updatedStructs = <InspectedStructure>[];
    for (final struct in report.structures) {
      final map = <String, List<ReportPhotoEntry>>{};
      for (var entry in struct.sectionPhotos.entries) {
        final list = <ReportPhotoEntry>[];
        for (var i = 0; i < entry.value.length; i++) {
          final pEntry = entry.value[i];
          final src = File(pEntry.photoUrl);
          final ext = p.extension(src.path);
          final dest = p.join(reportDir.path, '${struct.name}_${entry.key}_$i$ext');
          if (await src.exists()) {
            await src.copy(dest);
          }
          list.add(ReportPhotoEntry(
            label: pEntry.label,
            caption: pEntry.caption,
            confidence: pEntry.labelConfidence,
            photoUrl: dest,
            timestamp: pEntry.timestamp,
            latitude: pEntry.latitude,
            longitude: pEntry.longitude,
            damageType: pEntry.damageType,
            note: pEntry.note,
            sourceType: pEntry.sourceType,
            captureDevice: pEntry.captureDevice,
          ));
        }
        map[entry.key] = list;
      }
      updatedStructs.add(InspectedStructure(
        name: struct.name,
        sectionPhotos: map,
        slopeTestSquare: Map.from(struct.slopeTestSquare),
      ));
    }

    final saved = SavedReport(
      id: id,
      version: report.version,
      userId: report.userId,
      inspectionMetadata: report.inspectionMetadata,
      structures: updatedStructs,
      summary: report.summary,
      summaryText: report.summaryText,
      aiSummary: report.aiSummary,
      templateId: report.templateId,
      createdAt: report.createdAt,
      isFinalized: report.isFinalized,
      publicReportId: report.publicReportId,
      publicViewLink: report.publicViewLink,
      lastAuditPassed: report.lastAuditPassed,
      lastAuditIssues: report.lastAuditIssues,
      reportOwner: report.reportOwner,
      collaborators: report.collaborators,
      lastEditedBy: report.lastEditedBy,
      lastEditedAt: report.lastEditedAt,
    );

    final file = File(p.join(reportDir.path, 'report.json'));
    await file.writeAsString(jsonEncode(saved.toMap()));

    final ids = prefs.getStringList(_indexKey) ?? [];
    if (!ids.contains(id)) {
      ids.add(id);
      await prefs.setStringList(_indexKey, ids);
    }

    return id;
  }

  /// Loads all saved reports, optionally filtering by [inspectorName].
  Future<List<SavedReport>> loadReports({String? inspectorName}) async {
    final prefs = await SharedPreferences.getInstance();
    final base = await _reportsDir;
    final ids = prefs.getStringList(_indexKey) ?? [];
    final reports = <SavedReport>[];

    for (final id in ids) {
      final file = File(p.join(base.path, id, 'report.json'));
      if (!await file.exists()) continue;
      final data = await file.readAsString();
      final map = jsonDecode(data) as Map<String, dynamic>;
      final report = SavedReport.fromMap(map, id);
      if (inspectorName != null) {
        final meta =
            InspectionMetadata.fromMap(report.inspectionMetadata);
        if (meta.inspectorName != inspectorName) continue;
      }
      reports.add(report);
    }

    reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reports;
  }

  Future<void> saveSnapshot(SavedReport report) async {
    final base = await _reportsDir;
    final id = report.id.isNotEmpty ? report.id : 'snapshot';
    final dir = Directory(p.join(base.path, id));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File(
        p.join(dir.path, 'snapshot_${DateTime.now().millisecondsSinceEpoch}.json'));
    await file.writeAsString(jsonEncode(report.toMap()));
  }
}
