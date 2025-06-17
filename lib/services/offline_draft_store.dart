import 'package:hive/hive.dart';
import '../models/saved_report.dart';

class OfflineDraftStore {
  OfflineDraftStore._();
  static final OfflineDraftStore instance = OfflineDraftStore._();

  static const String boxName = 'draft_reports';
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox<Map>(boxName);
  }

  Future<void> saveReport(SavedReport report) async {
    final id = report.id.isNotEmpty
        ? report.id
        : DateTime.now().millisecondsSinceEpoch.toString();
    final local = SavedReport(
      id: id,
      version: report.version,
      userId: report.userId,
      inspectionMetadata: report.inspectionMetadata,
      structures: report.structures,
      summary: report.summary,
      summaryText: report.summaryText,
      aiSummary: report.aiSummary,
      signature: report.signature,
      publicReportId: report.publicReportId,
      publicViewLink: report.publicViewLink,
      templateId: report.templateId,
      createdAt: report.createdAt,
      isFinalized: report.isFinalized,
      signatureRequested: report.signatureRequested,
      signatureStatus: report.signatureStatus,
      homeownerSignature: report.homeownerSignature,
      theme: report.theme,
      lastAuditPassed: report.lastAuditPassed,
      lastAuditIssues: report.lastAuditIssues,
      changeLog: report.changeLog,
      snapshots: report.snapshots,
      attachments: report.attachments,
      reportOwner: report.reportOwner,
      collaborators: report.collaborators,
      lastEditedBy: report.lastEditedBy,
      lastEditedAt: report.lastEditedAt,
      latitude: report.latitude,
      longitude: report.longitude,
      searchIndex: report.searchIndex,
      localOnly: true,
    );
    await _box.put(id, local.toMap());
  }

  List<SavedReport> loadReports() {
    return _box.keys.map((key) {
      final map = Map<String, dynamic>.from(_box.get(key));
      return SavedReport.fromMap(map, key as String);
    }).toList();
  }

  Future<void> delete(String id) => _box.delete(id);

  int get count => _box.length;

  Future<void> clear() => _box.clear();
}
