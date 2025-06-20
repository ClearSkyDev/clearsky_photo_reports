import 'dart:async';

import '../models/inspected_structure.dart';
import '../models/saved_report.dart';
import '../utils/summary_utils.dart';
import 'ai_summary_service.dart';
// Inspector roles are defined in a separate model.
import '../models/inspector_report_role.dart';

/// Service that keeps an inspection summary up to date as photos are
/// labeled or edited. The summary is grouped by section and can be
/// manually overridden on a per-section basis.
class DynamicSummaryService {
  DynamicSummaryService({
    required this.aiService,
    Set<InspectorReportRole>? role,
  }) : role = role ?? {InspectorReportRole.ladderAssist};

  final AiSummaryService aiService;
  Set<InspectorReportRole> role;

  final _controller = StreamController<String>.broadcast();

  Map<String, String> _auto = {};
  final Map<String, String> _manual = {};

  /// Stream of the current combined summary.
  Stream<String> get summaryStream => _controller.stream;

  /// Current summary text.
  String get currentSummary => _compose();

  void dispose() {
    _controller.close();
  }

  /// Recompute summaries from the given report data.
  void updateReport(SavedReport report) {
    _auto = generateSectionSummaries(report);
    _emit();
  }

  /// Manually edit the summary for a specific section. The update is kept
  /// even when [updateReport] is called again.
  void editSection(String section, String text) {
    _manual[section] = text;
    _emit();
  }

  /// Use the AI service to rewrite a single section summary.
  Future<void> rewriteSection(String section, SavedReport report) async {
    final struct = report.structures.firstWhere(
      (s) => s.sectionPhotos.containsKey(section),
      orElse: () => InspectedStructure(name: '', sectionPhotos: {section: []}),
    );
    final subReport = SavedReport(
      inspectionMetadata: {
        ...report.inspectionMetadata,
        // Map the enum values to their string names for storage.
        'inspectorRoles': role.map((e) => e.name).toList(),
      },
      structures: [
        InspectedStructure(
          name: struct.name,
          sectionPhotos: {
            section: List.from(struct.sectionPhotos[section] ?? [])
          },
        )
      ],
    );
    try {
      final summary = await aiService.generateSummary(subReport);
      _manual[section] = summary.adjuster;
    } catch (_) {
      // ignore errors
    }
    _emit();
  }

  void _emit() {
    _controller.add(_compose());
  }

  String _compose() {
    final keys = {..._auto.keys, ..._manual.keys};
    final paragraphs = <String>[];
    for (final k in keys) {
      final text = _manual[k] ?? _auto[k];
      if (text != null && text.isNotEmpty) {
        paragraphs.add(text);
      }
    }
    return paragraphs.join('\n\n');
  }
}
