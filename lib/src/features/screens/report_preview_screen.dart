import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle, rootBundle;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/models/photo_entry.dart';
import '../../core/models/inspection_metadata.dart';
import '../../core/models/inspection_sections.dart';
import '../../core/models/saved_report.dart';
import '../../core/models/checklist.dart';
import '../../core/models/report_template.dart';
import '../../core/models/inspector_report_role.dart';
// Only used on web to trigger downloads
// ignore: avoid_web_libraries_in_flutter
// for web interop
import '../../web/js_utils.dart' as web_js;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'send_report_screen.dart';
import 'report_preview_webview.dart';
import '../widgets/export_progress_dialog.dart';
import 'report_settings_screen.dart' show ReportSettings;
import '../../core/utils/label_utils.dart';
import '../../core/models/report_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:path_provider/path_provider.dart' as pp;
import '../../core/utils/export_utils.dart';
import '../../core/utils/share_utils.dart';
import 'photo_map_screen.dart';
import '../../core/services/ai_summary_service.dart';
import '../../core/models/ai_summary.dart';
import '../../core/services/speech_service.dart';
import '../../core/services/tts_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/ai_disclaimer_banner.dart';

import '../../core/models/inspected_structure.dart';
import '../../core/utils/export_log.dart';
import '../../core/models/export_log_entry.dart';

class ReportPreviewScreen extends StatefulWidget {
  final List<PhotoEntry>? photos;
  final InspectionMetadata metadata;
  final List<InspectedStructure>? structures;
  final ReportTemplate? template;
  final bool readOnly;
  final String? summary;
  final SavedReport? savedReport;
  final Uint8List? signature;

  const ReportPreviewScreen({
    super.key,
    this.photos,
    this.structures,
    required this.metadata,
    this.template,
    this.readOnly = false,
    this.summary,
    this.savedReport,
    this.signature,
  });

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  static const String _contactInfo =
      'ClearSky Roof Inspectors | www.clearskyroof.com | (555) 123-4567';
  static const String _disclaimerText =
      '⚠️ AI-Assisted Report Disclaimer\nThis report was created using AI-assisted tools provided by ClearSky. The information within was input by the inspector and is their sole responsibility. ClearSky does not assume responsibility for any incorrect, incomplete, or misleading information submitted by users. Final coverage decisions should always be made by licensed professionals or carriers.';
  static const String _coverDisclaimer =
      'This report is a professional opinion based on visual inspection only.';
  late final InspectionMetadata _metadata;
  late final TextEditingController _summaryController;
  late final TextEditingController _adjusterSummaryController;
  late final TextEditingController _homeownerSummaryController;
  late final TextEditingController _jobCostController;
  late final TextEditingController _titleController;
  bool _editingSummaries = true;
  bool _loadingSummary = false;
  AiSummaryReview? _aiSummary;
  Uint8List? _signature;
  late Set<InspectorReportRole> _selectedRole;
  String _template = 'legacy';
  bool _showGps = true;
  ReportTheme _theme = ReportTheme.defaultTheme;
  bool _exporting = false;
  File? _exportedFile;

  @override
  void initState() {
    super.initState();
    _metadata = widget.metadata;
    _selectedRole = Set.from(_metadata.inspectorRoles);
    _summaryController = TextEditingController(text: widget.summary ?? '');
    _adjusterSummaryController = TextEditingController();
    _homeownerSummaryController = TextEditingController();
    _jobCostController =
        TextEditingController(text: widget.savedReport?.jobCost ?? '');
    _titleController = TextEditingController(text: _defaultReportTitle());
    _aiSummary = widget.savedReport?.aiSummary;
    if (_aiSummary != null) {
      _adjusterSummaryController.text = _aiSummary!.content;
      _editingSummaries = false;
    }
    _signature = widget.signature;
    inspectionChecklist.markComplete('Report Previewed');
    _loadTemplate();
    if (_aiSummary == null || _aiSummary!.status == 'rejected') {
      _generateSummary();
    }
  }

  Future<void> _loadTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('report_settings');
    final themeData = prefs.getString('report_theme');
    if (data != null) {
      final map = jsonDecode(data) as Map<String, dynamic>;
      final settings = ReportSettings.fromMap(map);
      if (!mounted) return;
      setState(() {
        _template = settings.template;
        _showGps = settings.showGpsData;
      });
    }
    if (themeData != null) {
      final map = jsonDecode(themeData) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _theme = ReportTheme.fromMap(map);
      });
    }
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _adjusterSummaryController.dispose();
    _homeownerSummaryController.dispose();
    _jobCostController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String _defaultReportTitle() {
    final lastName = _metadata.clientName.trim().split(' ').last;
    final date =
        _metadata.inspectionDate.toLocal().toIso8601String().split('T')[0];
    return '$lastName Roof - $date';
  }

  String _metadataFileName(String ext) {
    String sanitize(String input) {
      return input
          .trim()
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
    }

    final title = sanitize(_titleController.text.isNotEmpty
        ? _titleController.text
        : _defaultReportTitle());
    return '$title.$ext';
  }

  List<MapEntry<String, List<ReportPhotoEntry>>> _gatherGroups() {
    final List<MapEntry<String, List<ReportPhotoEntry>>> groups = [];

    if (widget.structures != null) {
      for (final struct in widget.structures!) {
        for (var section in widget.template?.sections ??
            sectionsForType(_metadata.inspectionType)) {
          final photos = struct.sectionPhotos[section] ?? [];
          if (photos.isNotEmpty) {
            final label = widget.structures!.length > 1
                ? '${struct.name} - $section'
                : section;
            groups.add(MapEntry(label, photos));
          }
        }
      }
    }

    return groups;
  }

  List<PhotoEntry> _gatherAllPhotos() {
    final List<PhotoEntry> all = [];
    if (widget.photos != null) {
      all.addAll(widget.photos!);
    }
    for (var group in _gatherGroups()) {
      for (var p in group.value) {
        final suffix =
            p.label.isNotEmpty && p.label != 'Unlabeled' ? ' - ${p.label}' : '';
        all.add(PhotoEntry(
          url: p.photoUrl,
          capturedAt: p.timestamp,
          label: '${group.key}$suffix',
          latitude: p.latitude,
          longitude: p.longitude,
          note: p.note,
        ));
      }
    }
    return all;
  }

  List<PhotoEntry> _gpsPhotos() {
    return _gatherAllPhotos()
        .where((p) => p.latitude != null && p.longitude != null)
        .toList();
  }

  List<String> _collectIssues(List<dynamic> photos,
      {bool missingTestSquare = false}) {
    final issues = <String>{};
    for (final p in photos) {
      final note = (p as dynamic).note as String?;
      if (note != null && note.isNotEmpty) issues.add(note);
      final damage = (p as dynamic).damageType as String?;
      if (damage != null && damage.isNotEmpty && damage != 'Unknown') {
        issues.add(formatDamageLabel(damage, _metadata.inspectorRoles));
      }
    }
    if (missingTestSquare) {
      issues.add('No test square photo included for this slope');
    }
    return issues.toList();
  }

  Widget _summaryField(TextEditingController controller, String label) {
    if (_editingSummaries) {
      return TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.mic),
            tooltip: 'Dictate ${label.toLowerCase()}',
            onPressed: () => _dictate(controller, label.toLowerCase()),
          ),
        ),
        maxLines: 3,
      );
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(controller.text),
        ],
      ),
    );
  }

  Future<void> _generateSummary() async {
    final metaMap = {
      'clientName': _metadata.clientName,
      'propertyAddress': _metadata.propertyAddress,
      'inspectionDate': _metadata.inspectionDate.toIso8601String(),
      'insuranceCarrier': _metadata.insuranceCarrier,
      'perilType': _metadata.perilType.name,
      'inspectionType': _metadata.inspectionType.name,
      'inspectorRoles': _metadata.inspectorRoles.map((e) => e.name).toList(),
      'inspectorName': _metadata.inspectorName,
    };
    final report = SavedReport(
      inspectionMetadata: metaMap,
      structures: widget.structures ?? [],
      summary: _summaryController.text,
      summaryText: _adjusterSummaryController.text,
    );
    final key = const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '')
            .isNotEmpty
        ? const String.fromEnvironment('OPENAI_API_KEY')
        : (Platform.environment['OPENAI_API_KEY'] ?? '');
    if (key.isEmpty) return;
    setState(() => _loadingSummary = true);
    var cancelled = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            const Text('Generating summary...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              cancelled = true;
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          )
        ],
      ),
    );
    try {
      final service = AiSummaryService(apiKey: key);
      final result = await service.generateSummary(report);
      if (!cancelled && mounted) {
        setState(() {
          _aiSummary =
              AiSummaryReview(content: result.adjuster, status: 'draft');
          _adjusterSummaryController.text = result.adjuster;
          _homeownerSummaryController.text = result.homeowner;
        });
      }
    } catch (_) {
      // ignore errors
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  Future<void> _regenerateWithRole() async {
    if (_selectedRole.difference(_metadata.inspectorRoles).isNotEmpty ||
        _metadata.inspectorRoles.difference(_selectedRole).isNotEmpty) {
      setState(() {
        _metadata = InspectionMetadata(
          clientName: _metadata.clientName,
          propertyAddress: _metadata.propertyAddress,
          inspectionDate: _metadata.inspectionDate,
          insuranceCarrier: _metadata.insuranceCarrier,
          perilType: _metadata.perilType,
          inspectionType: _metadata.inspectionType,
          inspectorName: _metadata.inspectorName,
          inspectorRoles: _selectedRole,
          reportId: _metadata.reportId,
          weatherNotes: _metadata.weatherNotes,
        );
      });
    }
    await _generateSummary();
  }

  // Generate the HTML string for the report preview
  String generateHtmlPreview(dynamic entry) {
    final buffer = StringBuffer();
    buffer.writeln('<html><head><title>Photo Report</title>');
    final color =
        '#${_theme.primaryColor.toRadixString(16).padLeft(8, '0').substring(2)}';
    String style;
    switch (_template) {
      case 'side':
        style = '.photo{width:48%;margin:1%;display:inline-block;}';
        break;
      case 'dark':
        style = 'body{background:#333;color:#eee;} a{color:$color;}';
        break;
      default:
        style =
            '.cover { text-align:center; padding:40px; } .cover table { margin:20px auto; border-collapse:collapse; } .cover td { padding:4px 8px; } .signature { margin-top:40px; }';
    }
    final bodyStyle = 'body { font-family:${_theme.fontFamily}, sans-serif; }';
    buffer.writeln('<style>$bodyStyle $style</style></head><body>');

    buffer.writeln('<div class="cover">');
    final logo = _theme.logoPath ?? 'assets/images/clearsky_logo.png';
    buffer.writeln('<img src="$logo" alt="Logo" style="width:200px;">');
    buffer.writeln('<h1>Roof Inspection Report</h1>');
    final preparedLabel =
        _metadata.inspectorRoles.contains(InspectorReportRole.adjuster)
            ? 'Prepared from Adjuster Perspective'
            : 'Prepared by: Third-Party Inspector';
    buffer.writeln(
        '<div style="position:absolute;top:10px;right:10px;font-size:12px;font-weight:bold;">$preparedLabel</div>');

    buffer.writeln('<table>');
    buffer.writeln(
        '<tr><td><strong>Client Name:</strong></td><td>${_metadata.clientName}</td></tr>');
    buffer.writeln(
        '<tr><td><strong>Property Address:</strong></td><td>${_metadata.propertyAddress}</td></tr>');
    buffer.writeln(
        '<tr><td><strong>Inspection Date:</strong></td><td>${_metadata.inspectionDate.toLocal().toString().split(" ")[0]}</td></tr>');
    buffer.writeln(
        '<tr><td><strong>Insurance Carrier:</strong></td><td>${_metadata.insuranceCarrier}</td></tr>');
    buffer.writeln(
        '<tr><td><strong>Peril Type:</strong></td><td>${_metadata.perilType.name}</td></tr>');
    buffer.writeln(
        '<tr><td><strong>Inspection Type:</strong></td><td>${_metadata.inspectionType.name}</td></tr>');
    final roleText = _metadata.inspectorRoles
        .map((e) => e.name.replaceAll('_', ' '))
        .join(', ');
    buffer.writeln(
        '<tr><td><strong>Inspector Role:</strong></td><td>$roleText</td></tr>');
    buffer.writeln(
        '<tr><td><strong>Inspector Name:</strong></td><td>${_metadata.inspectorName}</td></tr>');
    if (_metadata.reportId != null) {
      buffer.writeln(
          '<tr><td><strong>Report ID:</strong></td><td>${_metadata.reportId}</td></tr>');
    }
    if (_metadata.weatherNotes != null) {
      buffer.writeln(
          '<tr><td><strong>Weather Notes:</strong></td><td>${_metadata.weatherNotes}</td></tr>');
    }
    buffer.writeln('</table>');

    final showAiSummary = _aiSummary != null &&
        (_aiSummary!.status == 'approved' || _aiSummary!.status == 'edited');
    if (showAiSummary &&
        (_adjusterSummaryController.text.isNotEmpty ||
            _homeownerSummaryController.text.isNotEmpty)) {
      buffer.writeln(
          '<div style="border:1px solid #ccc;padding:8px;margin-top:20px;">');
      buffer.writeln('<strong>Inspection Summary</strong><br>');
      if (_adjusterSummaryController.text.isNotEmpty) {
        buffer.writeln(
            '<p><em>For Adjuster:</em> ${_adjusterSummaryController.text}</p>');
      }
      if (_homeownerSummaryController.text.isNotEmpty) {
        buffer.writeln(
            '<p><em>For Homeowner:</em> ${_homeownerSummaryController.text}</p>');
      }
      if (_aiSummary!.editor != null) {
        final ts = _aiSummary!.editedAt?.toLocal().toString().split(' ').first;
        buffer.writeln(
            '<p><em>Reviewed by ${_aiSummary!.editor} on $ts</em></p>');
      }
      buffer.writeln('</div>');
    }

    if (_summaryController.text.isNotEmpty) {
      buffer.writeln(
          '<div style="border:1px solid #ccc;padding:8px;margin-top:20px;">');
      buffer.writeln('<strong>Inspector Notes / Summary</strong><br>');
      buffer.writeln('<p>${_summaryController.text}</p>');
      if (_jobCostController.text.isNotEmpty) {
        buffer.writeln(
            '<p><strong>Estimated Job Cost:</strong> ${_jobCostController.text}</p>');
      }
      buffer.writeln('</div>');
    }

    if (_signature != null) {
      final encoded = base64Encode(_signature!);
      buffer.writeln(
          '<p class="signature"><img src="data:image/png;base64,$encoded" height="100"></p>');
    } else {
      buffer.writeln(
          '<p class="signature">Inspector Signature: ________________________________</p>');
    }
    buffer.writeln('<p style="font-size:12px;">$_coverDisclaimer</p>');
    buffer.writeln('</div>');
    buffer.writeln('<hr>');
    buffer.writeln('<h2>Inspection Checklist</h2>');
    buffer.writeln('<ul>');
    for (final step in inspectionChecklist.steps) {
      final icon = step.isComplete ? '✓' : '✗';
      final color = step.isComplete ? 'black' : 'red';
      final req = step.requiredPhotos > 0
          ? ' (${step.photosTaken}/${step.requiredPhotos})'
          : '';
      buffer.writeln('<li style="color:$color">$icon ${step.title}$req</li>');
    }
    buffer.writeln('</ul>');

    if (widget.structures != null) {
      const establishing = ['Address Photo', 'Front of House'];
      const ordered = [
        'Front Elevation & Accessories',
        'Right Elevation & Accessories',
        'Back Elevation & Accessories',
        'Left Elevation & Accessories',
        'Roof Edge',
        'Roof Slopes - Front',
        'Roof Slopes - Right',
        'Roof Slopes - Back',
        'Roof Slopes - Left',
      ];

      for (final struct in widget.structures!) {
        if (widget.structures!.length > 1) {
          buffer.writeln('<h2>${struct.name}</h2>');
        }

        final estPhotos = <ReportPhotoEntry>[];
        for (final sec in establishing) {
          estPhotos.addAll(struct.sectionPhotos[sec] ?? []);
        }
        if (estPhotos.isNotEmpty) {
          buffer.writeln('<h3>Establishing Shots</h3>');
          final issues = _collectIssues(estPhotos);
          if (issues.isNotEmpty) {
            buffer.writeln('<ul>');
            for (final i in issues) {
              buffer.writeln('<li>$i</li>');
            }
            buffer.writeln('</ul>');
          }
          buffer.writeln('<div style="display:flex;flex-wrap:wrap;">');
          for (var photo in estPhotos) {
            final label = photo.label.isNotEmpty ? photo.label : 'Unlabeled';
            final damage =
                formatDamageLabel(photo.damageType, _metadata.inspectorRoles);
            final caption = damage.isNotEmpty ? '$label - $damage' : label;
            final containerClass = _template == 'side'
                ? 'class="photo"'
                : 'style="width:300px;margin:5px;text-align:center;"';
            buffer.writeln('<div $containerClass>');
            buffer.writeln(
                '<img src="${photo.photoUrl}" width="300" height="300" style="object-fit:cover;"><br>');
            final ts =
                photo.timestamp?.toLocal().toString().split('.').first ?? '';
            String gps = '';
            if (_showGps && photo.latitude != null && photo.longitude != null) {
              gps =
                  '<br><a href="https://www.google.com/maps/search/?api=1&query=${photo.latitude},${photo.longitude}">${photo.latitude!.toStringAsFixed(4)}, ${photo.longitude!.toStringAsFixed(4)}</a>';
            }
            final note =
                photo.note.isNotEmpty ? '<br><em>${photo.note}</em>' : '';
            buffer.writeln('<span>$caption<br>$ts$gps$note</span>');
            buffer.writeln('</div>');
          }
          buffer.writeln('</div>');
        }

        final otherSections = <String>{
          ...ordered,
          ...struct.sectionPhotos.keys
        };

        for (final section in ordered) {
          if (!otherSections.contains(section)) continue;
          final photos = struct.sectionPhotos[section] ?? [];
          if (photos.isEmpty) continue;
          final label = section.replaceAll(' & Accessories', '');
          buffer.writeln('<h3>$label</h3>');
          final missing = struct.slopeTestSquare[section] == false;
          final issues = _collectIssues(photos, missingTestSquare: missing);
          if (issues.isNotEmpty) {
            buffer.writeln('<ul>');
            for (final i in issues) {
              buffer.writeln('<li>$i</li>');
            }
            buffer.writeln('</ul>');
          }
          buffer.writeln('<div style="display:flex;flex-wrap:wrap;">');
          for (var photo in photos) {
            final labelText =
                photo.label.isNotEmpty ? photo.label : 'Unlabeled';
            final damage =
                formatDamageLabel(photo.damageType, _metadata.inspectorRoles);
            final caption =
                damage.isNotEmpty ? '$labelText - $damage' : labelText;
            final containerClass = _template == 'side'
                ? 'class="photo"'
                : 'style="width:300px;margin:5px;text-align:center;"';
            buffer.writeln('<div $containerClass>');
            buffer.writeln(
                '<img src="${photo.photoUrl}" width="300" height="300" style="object-fit:cover;"><br>');
            final ts =
                photo.timestamp?.toLocal().toString().split('.').first ?? '';
            String gps = '';
            if (_showGps && photo.latitude != null && photo.longitude != null) {
              gps =
                  '<br><a href="https://www.google.com/maps/search/?api=1&query=${photo.latitude},${photo.longitude}">${photo.latitude!.toStringAsFixed(4)}, ${photo.longitude!.toStringAsFixed(4)}</a>';
            }
            final note =
                photo.note.isNotEmpty ? '<br><em>${photo.note}</em>' : '';
            buffer.writeln('<span>$caption<br>$ts$gps$note</span>');
            buffer.writeln('</div>');
          }
          buffer.writeln('</div>');
        }

        for (final entry in struct.sectionPhotos.entries) {
          if (ordered.contains(entry.key) || establishing.contains(entry.key)) {
            continue;
          }
          final photos = entry.value;
          if (photos.isEmpty) continue;
          buffer.writeln('<h3>${entry.key}</h3>');
          final missing = struct.slopeTestSquare[entry.key] == false;
          final issues = _collectIssues(photos, missingTestSquare: missing);
          if (issues.isNotEmpty) {
            buffer.writeln('<ul>');
            for (final i in issues) {
              buffer.writeln('<li>$i</li>');
            }
            buffer.writeln('</ul>');
          }
          buffer.writeln('<div style="display:flex;flex-wrap:wrap;">');
          for (var photo in photos) {
            final labelText =
                photo.label.isNotEmpty ? photo.label : 'Unlabeled';
            final damage =
                formatDamageLabel(photo.damageType, _metadata.inspectorRoles);
            final caption =
                damage.isNotEmpty ? '$labelText - $damage' : labelText;
            final containerClass = _template == 'side'
                ? 'class="photo"'
                : 'style="width:300px;margin:5px;text-align:center;"';
            buffer.writeln('<div $containerClass>');
            buffer.writeln(
                '<img src="${photo.photoUrl}" width="300" height="300" style="object-fit:cover;"><br>');
            final ts =
                photo.timestamp?.toLocal().toString().split('.').first ?? '';
            String gps = '';
            if (_showGps && photo.latitude != null && photo.longitude != null) {
              gps =
                  '<br><a href="https://www.google.com/maps/search/?api=1&query=${photo.latitude},${photo.longitude}">${photo.latitude!.toStringAsFixed(4)}, ${photo.longitude!.toStringAsFixed(4)}</a>';
            }
            final note =
                photo.note.isNotEmpty ? '<br><em>${photo.note}</em>' : '';
            buffer.writeln('<span>$caption<br>$ts$gps$note</span>');
            buffer.writeln('</div>');
          }
          buffer.writeln('</div>');
        }
      }
    }

    buffer.writeln(
        '<p style="text-align: center; margin-top: 40px;">$_contactInfo</p>');
    String footer = _disclaimerText;
    buffer.writeln(
        '<footer style="background:#eee;padding:10px;margin-top:20px;font-size:12px;text-align:center;">$footer</footer>');
    buffer.writeln('</body></html>');

    return buffer.toString();
  }

  // HTML download
  Future<void> _downloadHtml() async {
    final htmlContent = generateHtmlPreview(null);
    await _saveHtmlFile(htmlContent);
    inspectionChecklist.markComplete('Report Exported');
    ExportLog.addEntry(ExportLogEntry(
      reportName: _metadata.propertyAddress,
      type: 'html',
      wasOffline: widget.savedReport?.wasOffline ?? false,
    ));
  }

  Future<void> _saveHtmlFile(String htmlContent) async {
    final bytes = utf8.encode(htmlContent);
    if (kIsWeb) {
      final fileName = _metadataFileName('html');
      web_js.downloadBytes(Uint8List.fromList(bytes), fileName, 'text/html');
    } else {
      Directory? dir;
      try {
        dir = await pp.getDownloadsDirectory();
      } catch (_) {
        dir = await pp.getApplicationDocumentsDirectory();
      }
      dir ??= await pp.getApplicationDocumentsDirectory();
      final path = p.join(dir.path, _metadataFileName('html'));
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      setState(() => _exportedFile = file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('HTML exported')),
        );
      }
    }
  }

  void _openMap(double lat, double lng) {
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    url_launcher.launchUrl(uri,
        mode: url_launcher.LaunchMode.externalApplication);
  }

  Future<void> _dictate(TextEditingController controller, String field) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(const SnackBar(content: Text('Listening...')));
    final text = await SpeechService.instance.record(
      fieldType: field,
      reportId: _metadata.reportId ?? widget.savedReport?.id ?? '',
    );
    scaffold.hideCurrentSnackBar();
    if (!mounted) return;
    if (text == null) return;
    final use = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Use this text?'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Use'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (use == true) {
      setState(() {
        if (controller.text.isEmpty) {
          controller.text = text;
        } else {
          controller.text = '${controller.text} $text';
        }
      });
    } else if (use == false) {
      await _dictate(controller, field);
    }
  }

  pw.Widget _pdfSectionHeader(String text) {
    if (_template == 'modern') {
      return pw.Container(
        color: PdfColor.fromInt(_theme.primaryColor),
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(_theme.primaryColor),
          ),
        ),
      );
    }
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromInt(_theme.primaryColor),
      ),
    );
  }

  // Helper to load all images before PDF generation
  Future<List<pw.Widget>> _buildPdfWidgets() async {
    final List<pw.Widget> widgets = [];

    Future<pw.Widget> buildWrap(List<ReportPhotoEntry> photos) async {
      final items = <pw.Widget>[];
      for (var photo in photos) {
        final imageData =
            await NetworkAssetBundle(Uri.parse(photo.photoUrl)).load("");
        final bytes = imageData.buffer.asUint8List();
        final label = photo.label.isNotEmpty ? photo.label : 'Unlabeled';
        final damage =
            formatDamageLabel(photo.damageType, _metadata.inspectorRoles);
        final caption = damage.isNotEmpty ? '$label - $damage' : label;

        items.add(
          pw.Container(
            width: 150,
            child: pw.Column(
              children: [
                pw.Image(pw.MemoryImage(bytes),
                    width: 150, height: 150, fit: pw.BoxFit.cover),
                pw.SizedBox(height: 4),
                pw.Text(caption,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 12)),
                pw.Text(
                    photo.timestamp?.toLocal().toString().split('.').first ??
                        '',
                    style: const pw.TextStyle(fontSize: 10)),
                if (_showGps &&
                    photo.latitude != null &&
                    photo.longitude != null)
                  pw.UrlLink(
                    destination:
                        'https://www.google.com/maps/search/?api=1&query=${photo.latitude},${photo.longitude}',
                    child: pw.Text(
                      '${photo.latitude!.toStringAsFixed(4)}, ${photo.longitude!.toStringAsFixed(4)}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                  ),
                if (photo.note.isNotEmpty)
                  pw.Text(photo.note,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          fontSize: 10, fontStyle: pw.FontStyle.italic)),
              ],
            ),
          ),
        );
      }

      return pw.Wrap(spacing: 10, runSpacing: 10, children: items);
    }

    if (widget.structures != null) {
      const establishing = ['Address Photo', 'Front of House'];
      const ordered = [
        'Front Elevation & Accessories',
        'Right Elevation & Accessories',
        'Back Elevation & Accessories',
        'Left Elevation & Accessories',
        'Roof Edge',
        'Roof Slopes - Front',
        'Roof Slopes - Right',
        'Roof Slopes - Back',
        'Roof Slopes - Left',
      ];

      for (final struct in widget.structures!) {
        if (widget.structures!.length > 1) {
          widgets.add(_pdfSectionHeader(struct.name));
          widgets.add(pw.SizedBox(height: 10));
        }

        final estPhotos = <ReportPhotoEntry>[];
        for (final sec in establishing) {
          estPhotos.addAll(struct.sectionPhotos[sec] ?? []);
        }
        if (estPhotos.isNotEmpty) {
          widgets.add(_pdfSectionHeader('Establishing Shots'));
          final issues = _collectIssues(estPhotos);
          if (issues.isNotEmpty) {
            widgets.add(pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Noted Issues:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ...issues.map((e) => pw.Bullet(text: e)),
                ]));
            widgets.add(pw.SizedBox(height: 8));
          }
          widgets.add(await buildWrap(estPhotos));
          widgets.add(pw.SizedBox(height: 20));
        }

        final otherSections = <String>{
          ...ordered,
          ...struct.sectionPhotos.keys
        };

        for (final section in ordered) {
          if (!otherSections.contains(section)) continue;
          final photos = struct.sectionPhotos[section] ?? [];
          if (photos.isEmpty) continue;
          final label = section.replaceAll(' & Accessories', '');
          widgets.add(_pdfSectionHeader(label));
          final issues = _collectIssues(photos);
          if (issues.isNotEmpty) {
            widgets.add(pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Noted Issues:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ...issues.map((e) => pw.Bullet(text: e)),
                ]));
            widgets.add(pw.SizedBox(height: 8));
          }
          widgets.add(await buildWrap(photos));
          widgets.add(pw.SizedBox(height: 20));
        }

        for (final entry in struct.sectionPhotos.entries) {
          if (ordered.contains(entry.key) || establishing.contains(entry.key)) {
            continue;
          }
          final photos = entry.value;
          if (photos.isEmpty) continue;
          widgets.add(_pdfSectionHeader(entry.key));
          final issues = _collectIssues(photos);
          if (issues.isNotEmpty) {
            widgets.add(pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Noted Issues:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ...issues.map((e) => pw.Bullet(text: e)),
                ]));
            widgets.add(pw.SizedBox(height: 8));
          }
          widgets.add(await buildWrap(photos));
          widgets.add(pw.SizedBox(height: 20));
        }
      }
    }

    return widgets;
  }

  // Generate PDF bytes for the current report
  Future<Uint8List> _downloadPdf() async {
    final pdf = pw.Document();
    final widgets = await _buildPdfWidgets();
    final logoAsset = _theme.logoPath ?? 'assets/images/clearsky_logo.png';
    final logoData = await rootBundle.load(logoAsset);
    final logoBytes = logoData.buffer.asUint8List();
    final dateStr = DateTime.now().toLocal().toString().split(' ')[0];

    pdf
      ..addPage(
        pw.MultiPage(
          footer: (context) => pw.Container(
            color: PdfColors.grey300,
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(_disclaimerText,
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 2),
                pw.Text(_contactInfo,
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center),
              ],
            ),
          ),
          build: (context) => [
            pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Image(pw.MemoryImage(logoBytes), width: 150),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'Roof Inspection Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(_theme.primaryColor),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    _metadata.inspectorRoles
                            .contains(InspectorReportRole.adjuster)
                        ? 'Prepared from Adjuster Perspective'
                        : 'Prepared by: Third-Party Inspector',
                    style: pw.TextStyle(
                      fontSize: 18,
                      color: PdfColor.fromInt(_theme.primaryColor),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text('Client Name: ${_metadata.clientName}'),
                  pw.Text('Property Address: ${_metadata.propertyAddress}'),
                  pw.Text(
                      'Inspection Date: ${_metadata.inspectionDate.toLocal().toString().split(' ')[0]}'),
                  pw.Text('Insurance Carrier: ${_metadata.insuranceCarrier}'),
                  pw.Text('Peril Type: ${_metadata.perilType.name}'),
                  pw.Text('Inspection Type: ${_metadata.inspectionType.name}'),
                  pw.Text(
                      'Inspector Role: ${_metadata.inspectorRoles.map((e) => e.name.replaceAll('_', ' ')).join(', ')}'),
                  pw.Text('Inspector Name: ${_metadata.inspectorName}'),
                  pw.SizedBox(height: 20),
                  if ((_aiSummary?.status == 'approved' ||
                          _aiSummary?.status == 'edited') &&
                      (_adjusterSummaryController.text.isNotEmpty ||
                          _homeownerSummaryController.text.isNotEmpty))
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey)),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Inspection Summary',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          if (_adjusterSummaryController.text.isNotEmpty) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(
                                'For Adjuster: ${_adjusterSummaryController.text}'),
                          ],
                          if (_homeownerSummaryController.text.isNotEmpty) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(
                                'For Homeowner: ${_homeownerSummaryController.text}'),
                          ],
                          if (_aiSummary?.editor != null)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 4),
                              child: pw.Text(
                                  'Reviewed by ${_aiSummary!.editor} on ${_aiSummary!.editedAt?.toLocal().toString().split(' ')[0]}',
                                  style: const pw.TextStyle(fontSize: 10)),
                            )
                        ],
                      ),
                    ),
                  if (_summaryController.text.isNotEmpty)
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey)),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Inspector Notes / Summary',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 4),
                          pw.Text(_summaryController.text),
                          if (_jobCostController.text.isNotEmpty)
                            pw.Text(
                                'Estimated Job Cost: ${_jobCostController.text}'),
                        ],
                      ),
                    ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    _coverDisclaimer,
                    style: const pw.TextStyle(fontSize: 12),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      )
      ..addPage(
        pw.MultiPage(
          footer: (context) => pw.Container(
            color: PdfColors.grey300,
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(_disclaimerText,
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 2),
                pw.Text(_contactInfo,
                    style: const pw.TextStyle(fontSize: 9),
                    textAlign: pw.TextAlign.center),
              ],
            ),
          ),
          build: (pw.Context context) => [
            pw.Header(level: 0, text: 'ClearSky Photo Report'),
            pw.Text('Client Name: ${_metadata.clientName}'),
            pw.Text('Property Address: ${_metadata.propertyAddress}'),
            pw.Text(
                'Inspection Date: ${_metadata.inspectionDate.toLocal().toString().split(' ')[0]}'),
            pw.Text('Insurance Carrier: ${_metadata.insuranceCarrier}'),
            pw.Text('Peril Type: ${_metadata.perilType.name}'),
            pw.Text('Inspection Type: ${_metadata.inspectionType.name}'),
            pw.Text(
                'Inspector Role: ${_metadata.inspectorRoles.map((e) => e.name.replaceAll('_', ' ')).join(', ')}'),
            pw.Text('Inspector Name: ${_metadata.inspectorName}'),
            pw.SizedBox(height: 20),
            pw.Text('Inspection Checklist',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final step in inspectionChecklist.steps)
                  pw.Row(children: [
                    pw.Text(step.isComplete ? '✓' : '✗',
                        style: pw.TextStyle(
                            color: step.isComplete
                                ? PdfColors.black
                                : PdfColors.red)),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      step.requiredPhotos > 0
                          ? '${step.title} (${step.photosTaken}/${step.requiredPhotos})'
                          : step.title,
                      style: pw.TextStyle(
                          color: step.isComplete
                              ? PdfColors.black
                              : PdfColors.red),
                    ),
                  ])
              ],
            ),
            pw.SizedBox(height: 20),
            ...widgets,
            pw.SizedBox(height: 40),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Inspector Signature'),
                pw.SizedBox(height: 4),
                if (_signature != null)
                  pw.Image(pw.MemoryImage(_signature!), height: 80)
                else
                  pw.Container(
                      height: 1,
                      width: double.infinity,
                      color: PdfColors.black),
                pw.Text('${_metadata.inspectorName} – $dateStr'),
              ],
            ),
          ],
        ),
      );

    return pdf.save();
  }

  Future<void> _exportPdf() async {
    final bytes = await _downloadPdf();
    final fileName = _metadataFileName('pdf');
    if (kIsWeb) {
      web_js.downloadBytes(bytes, fileName, 'application/pdf');
      return;
    }

    Directory? dir;
    try {
      dir = await pp.getDownloadsDirectory();
    } catch (_) {
      dir = await pp.getApplicationDocumentsDirectory();
    }
    dir ??= await pp.getApplicationDocumentsDirectory();

    final path = p.join(dir.path, fileName);
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    if (!mounted) return;
    setState(() => _exportedFile = file);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF exported')),
    );
    inspectionChecklist.markComplete('Report Exported');
    ExportLog.addEntry(ExportLogEntry(
      reportName: _metadata.propertyAddress,
      type: 'pdf',
      wasOffline: widget.savedReport?.wasOffline ?? false,
    ));
  }

  Future<void> _exportZip() async {
    if (widget.savedReport == null || _exporting) return;
    setState(() => _exporting = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ExportProgressDialog(),
    );
    try {
      final file = await exportFinalZip(widget.savedReport!);
      if (mounted) {
        setState(() => _exportedFile = file);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ZIP exported')),
        );
        inspectionChecklist.markComplete('Report Exported');
      }
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _shareReport() async {
    if (_exportedFile == null) return;
    final subject = 'Roof Inspection Report for ${_metadata.clientName}';
    final inspector =
        _metadata.inspectorName != null ? ' by ${_metadata.inspectorName}' : '';
    final body =
        'Attached is the roof inspection report for ${_metadata.clientName}$inspector.';
    await shareReportFile(_exportedFile!, subject: subject, text: body);
  }

  void _previewFullReport() {
    final htmlContent = generateHtmlPreview(null);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewWebView(
          html: htmlContent,
          onExportPdf: _exportPdf,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Report')),
      body: Column(
        children: [
          if (widget.savedReport?.isFinalized == true)
            Container(
              width: double.infinity,
              color: Colors.redAccent,
              padding: const EdgeInsets.all(8),
              child: const Text(
                'FINALIZED',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          if (widget.savedReport?.wasOffline == true)
            Container(
              width: double.infinity,
              color: Colors.yellow,
              padding: const EdgeInsets.all(8),
              child: const Text(
                '⚠️ Draft Created Offline — Please verify all data before submission',
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Client Name: ${_metadata.clientName}'),
                Text('Property Address: ${_metadata.propertyAddress}'),
                Text(
                    'Inspection Date: ${_metadata.inspectionDate.toLocal().toString().split(" ")[0]}'),
                Text('Insurance Carrier: ${_metadata.insuranceCarrier}'),
                Text('Peril Type: ${_metadata.perilType.name}'),
                Text('Inspection Type: ${_metadata.inspectionType.name}'),
                Row(
                  children: [
                    const Text('Inspector Role: '),
                    Wrap(
                      spacing: 4,
                      children: [
                        for (final r in InspectorReportRole.values)
                          FilterChip(
                            selected: _selectedRole.contains(r),
                            label: Text(r.name.replaceAll('_', ' ')),
                            onSelected: widget.readOnly
                                ? null
                                : (val) {
                                    setState(() {
                                      if (val) {
                                        _selectedRole.add(r);
                                      } else {
                                        _selectedRole.remove(r);
                                      }
                                      _metadata = InspectionMetadata(
                                        clientName: _metadata.clientName,
                                        propertyAddress:
                                            _metadata.propertyAddress,
                                        inspectionDate:
                                            _metadata.inspectionDate,
                                        insuranceCarrier:
                                            _metadata.insuranceCarrier,
                                        perilType: _metadata.perilType,
                                        inspectionType:
                                            _metadata.inspectionType,
                                        inspectorName: _metadata.inspectorName,
                                        inspectorRoles: _selectedRole,
                                        reportId: _metadata.reportId,
                                        weatherNotes: _metadata.weatherNotes,
                                      );
                                    });
                                  },
                          ),
                      ],
                    ),
                  ],
                ),
                Text('Inspector Name: ${_metadata.inspectorName}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Report Title'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: widget.readOnly
                ? Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(8),
                    decoration:
                        BoxDecoration(border: Border.all(color: Colors.grey)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inspector Notes / Summary',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(_summaryController.text),
                      ],
                    ),
                  )
                : TextField(
                    controller: _summaryController,
                    decoration: InputDecoration(
                      labelText: 'Inspector Notes / Summary',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.mic),
                        tooltip: 'Dictate summary',
                        onPressed: () =>
                            _dictate(_summaryController, 'summary'),
                      ),
                    ),
                    maxLines: 3,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextField(
              controller: _jobCostController,
              decoration:
                  const InputDecoration(labelText: 'Estimated Job Cost'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _summaryField(_adjusterSummaryController, 'Adjuster Summary'),
                const SizedBox(height: 8),
                _summaryField(_homeownerSummaryController, 'Homeowner Summary'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => TtsService.instance
                          .speak(_adjusterSummaryController.text),
                      child: const Text('Play Summary'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loadingSummary ? null : _generateSummary,
                      child: const Text('Regenerate'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loadingSummary ? null : _regenerateWithRole,
                      child:
                          const Text('Regenerate Summary with Different Role'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _editingSummaries = true;
                        });
                      },
                      child: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final user = FirebaseAuth.instance.currentUser;
                        setState(() {
                          _aiSummary = AiSummaryReview(
                            status: 'approved',
                            content: _adjusterSummaryController.text,
                            editor: user?.email,
                            editedAt: DateTime.now(),
                          );
                          _editingSummaries = false;
                        });
                      },
                      child: const Text('Approve'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final user = FirebaseAuth.instance.currentUser;
                        setState(() {
                          _aiSummary = AiSummaryReview(
                            status: 'rejected',
                            content: _adjusterSummaryController.text,
                            editor: user?.email,
                            editedAt: DateTime.now(),
                          );
                        });
                      },
                      child: const Text('Reject'),
                    ),
                  ],
                )
              ],
            ),
          ),
          if (_signature != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Inspector Signature',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Image.memory(_signature!, height: 100),
                ],
              ),
            ),
          Expanded(
            child: Builder(
              builder: (context) {
                final groups = _gatherGroups();
                return ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, gIndex) {
                    final group = groups[gIndex];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            group.key,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: group.value.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                          ),
                          itemBuilder: (context, index) {
                            final photo = group.value[index];
                            final label = photo.label.isNotEmpty
                                ? photo.label
                                : 'Unlabeled';
                            return Column(
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: Image.network(photo.photoUrl,
                                      fit: BoxFit.cover),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Column(
                                    children: [
                                      Text(label),
                                      Text(
                                        photo.timestamp
                                                ?.toLocal()
                                                .toString()
                                                .split('.')
                                                .first ??
                                            '',
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      if (_showGps &&
                                          photo.latitude != null &&
                                          photo.longitude != null)
                                        GestureDetector(
                                          onTap: () => _openMap(photo.latitude!,
                                              photo.longitude!),
                                          child: Text(
                                            '${photo.latitude!.toStringAsFixed(4)}, ${photo.longitude!.toStringAsFixed(4)}',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                decoration:
                                                    TextDecoration.underline),
                                          ),
                                        ),
                                      if (photo.note.isNotEmpty)
                                        Text(
                                          photo.note,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              fontStyle: FontStyle.italic),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _downloadHtml,
                  child: const Text("Download HTML"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _exportPdf,
                  child: const Text("Download PDF"),
                ),
                if (widget.savedReport != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _exporting ? null : _exportZip,
                    child: _exporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Download ZIP'),
                  ),
                if (_exportedFile != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _shareReport,
                    child: const Text('Share Report'),
                  ),
                if (_gpsPhotos().isNotEmpty)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PhotoMapScreen(photos: _gpsPhotos()),
                        ),
                      );
                    },
                    child: const Text('View Inspection Map'),
                  ),
                const AiDisclaimerBanner(),
              ],
            ),
          ),
          if (!widget.readOnly) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                onPressed: _previewFullReport,
                child: const Text('Preview Full Report'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SendReportScreen(
                        metadata: _metadata,
                        structures: widget.structures,
                        summary: _summaryController.text,
                        summaryText: _adjusterSummaryController.text,
                        signature: _signature,
                        template: widget.template,
                      ),
                    ),
                  );
                },
                child: const Text('Finalize & Send'),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
