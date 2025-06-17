import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle, rootBundle;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/photo_entry.dart';
import '../models/inspection_metadata.dart';
import '../models/inspection_type.dart';
import '../models/inspection_sections.dart';
import '../models/saved_report.dart';
import '../models/inspected_structure.dart';
import '../models/checklist.dart';
import '../models/report_template.dart';
import 'dart:html' as html; // for HTML download (web only)
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'send_report_screen.dart';
import 'report_preview_webview.dart';
import 'report_settings_screen.dart' show ReportSettings;
import '../models/report_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/export_utils.dart';
import '../utils/share_utils.dart';
import 'photo_map_screen.dart';
import '../services/ai_summary_service.dart';
import '../models/ai_summary.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/inspected_structure.dart';

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
      'This report is for informational purposes only and is not a warranty.';
  static const String _coverDisclaimer =
      'This report is a professional opinion based on visual inspection only.';
  late final InspectionMetadata _metadata;
  late final TextEditingController _summaryController;
  late final TextEditingController _adjusterSummaryController;
  late final TextEditingController _homeownerSummaryController;
  bool _editingSummaries = true;
  bool _loadingSummary = false;
  AiSummaryReview? _aiSummary;
  Uint8List? _signature;
  String _template = 'legacy';
  bool _showGps = true;
  ReportTheme _theme = ReportTheme.defaultTheme;
  bool _exporting = false;
  File? _exportedFile;

  @override
  void initState() {
    super.initState();
    _metadata = widget.metadata;
    _summaryController = TextEditingController(text: widget.summary ?? '');
    _adjusterSummaryController = TextEditingController();
    _homeownerSummaryController = TextEditingController();
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
      setState(() {
        _template = settings.template;
        _showGps = settings.showGpsData;
      });
    }
    if (themeData != null) {
      final map = jsonDecode(themeData) as Map<String, dynamic>;
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
    super.dispose();
  }
  String _metadataFileName(String ext) {
    String sanitize(String input) {
      return input
          .trim()
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_');
    }

    final address = sanitize(_metadata.propertyAddress);
    final date = sanitize(
        _metadata.inspectionDate.toLocal().toIso8601String().split('T')[0]);
    return '${address}_${date}_clearsky_report.$ext';
  }
  void _updateLabel(int index, String value) {
    if (widget.photos == null) return;
    setState(() {
      widget.photos![index].label = value;
    });
  }

  List<MapEntry<String, List<PhotoEntry>>> _gatherGroups() {
    final List<MapEntry<String, List<PhotoEntry>>> groups = [];

    if (widget.structures != null) {
      for (final struct in widget.structures!) {
        for (var section
            in widget.template?.sections ?? sectionsForType(_metadata.inspectionType)) {
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
        final suffix = p.label != 'Unlabeled' ? ' - ${p.label}' : '';
        all.add(PhotoEntry(
            url: p.url,
            label: '${group.key}$suffix',
            latitude: p.latitude,
            longitude: p.longitude,
            note: p.note));
      }
    }
    return all;
  }

  List<PhotoEntry> _gpsPhotos() {
    return _gatherAllPhotos()
        .where((p) => p.latitude != null && p.longitude != null)
        .toList();
  }

  Widget _summaryField(TextEditingController controller, String label) {
    if (_editingSummaries) {
      return TextField(
        controller: controller,
        decoration:
            InputDecoration(labelText: label, border: const OutlineInputBorder()),
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
      if (_metadata.insuranceCarrier != null)
        'insuranceCarrier': _metadata.insuranceCarrier,
      'perilType': _metadata.perilType.name,
      'inspectionType': _metadata.inspectionType.name,
      'inspectorRole': _metadata.inspectorRole.name,
      if (_metadata.inspectorName != null)
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
    try {
      final service = AiSummaryService(apiKey: key);
      final result = await service.generateSummary(report);
      setState(() {
        _aiSummary = AiSummaryReview(content: result.adjuster, status: 'draft');
        _adjusterSummaryController.text = result.adjuster;
        _homeownerSummaryController.text = result.homeowner;
      });
    } catch (_) {
      // ignore errors
    } finally {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  // Generate the HTML string for the report preview
  String generateHtmlPreview() {
    final buffer = StringBuffer();
    buffer.writeln('<html><head><title>Photo Report</title>');
    final color = '#${_theme.primaryColor.toRadixString(16).padLeft(8, '0').substring(2)}';
    String style;
    switch (_template) {
      case 'modern':
        style =
            'h2 { background:$color; padding:4px; }';
        break;
      case 'clean':
        style =
            'h2 { border-bottom:1px solid $color; }';
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
        _metadata.inspectorRole == InspectorReportRole.adjuster
            ? 'Prepared from Adjuster Perspective'
            : 'Prepared by: Third-Party Inspector';
    buffer.writeln(
        '<div style="position:absolute;top:10px;right:10px;font-size:12px;font-weight:bold;">$preparedLabel</div>');

    buffer.writeln('<table>');
    buffer.writeln('<tr><td><strong>Client Name:</strong></td><td>${_metadata.clientName}</td></tr>');
    buffer.writeln('<tr><td><strong>Property Address:</strong></td><td>${_metadata.propertyAddress}</td></tr>');
    buffer.writeln('<tr><td><strong>Inspection Date:</strong></td><td>${_metadata.inspectionDate.toLocal().toString().split(" ")[0]}</td></tr>');
    if (_metadata.insuranceCarrier != null) {
      buffer.writeln('<tr><td><strong>Insurance Carrier:</strong></td><td>${_metadata.insuranceCarrier}</td></tr>');
    }
    buffer.writeln('<tr><td><strong>Peril Type:</strong></td><td>${_metadata.perilType.name}</td></tr>');
    buffer.writeln('<tr><td><strong>Inspection Type:</strong></td><td>${_metadata.inspectionType.name}</td></tr>');
    buffer.writeln('<tr><td><strong>Inspector Role:</strong></td><td>${_metadata.inspectorRole.name.replaceAll('_', ' ')}</td></tr>');
    if (_metadata.inspectorName != null) {
      buffer.writeln('<tr><td><strong>Inspector Name:</strong></td><td>${_metadata.inspectorName}</td></tr>');
    }
    if (_metadata.reportId != null) {
      buffer.writeln('<tr><td><strong>Report ID:</strong></td><td>${_metadata.reportId}</td></tr>');
    }
    if (_metadata.weatherNotes != null) {
      buffer.writeln('<tr><td><strong>Weather Notes:</strong></td><td>${_metadata.weatherNotes}</td></tr>');
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
      buffer.writeln('</div>');
    }

    if (_signature != null) {
      final encoded = base64Encode(_signature!);
      buffer.writeln(
          '<p class="signature"><img src="data:image/png;base64,$encoded" height="100"></p>');
    } else {
      buffer.writeln('<p class="signature">Inspector Signature: ________________________________</p>');
    }
    buffer.writeln('<p style="font-size:12px;">$_coverDisclaimer</p>');
    buffer.writeln('</div>');
    buffer.writeln('<hr>');
    buffer.writeln('<h2>Inspection Checklist</h2>');
    buffer.writeln('<ul>');
    for (final step in inspectionChecklist.steps) {
      final icon = step.isComplete ? '✓' : '✗';
      final color = step.isComplete ? 'black' : 'red';
      final req = step.requiredPhotos > 0 ? ' (${step.photosTaken}/${step.requiredPhotos})' : '';
      buffer.writeln('<li style="color:$color">$icon ${step.title}$req</li>');
    }
    buffer.writeln('</ul>');

    if (widget.structures != null) {
      for (final struct in widget.structures!) {
        if (widget.structures!.length > 1) {
          buffer.writeln('<h2>${struct.name}</h2>');
        }
        for (var section
            in widget.template?.sections ?? sectionsForType(_metadata.inspectionType)) {
          final photos = struct.sectionPhotos[section] ?? [];
          if (photos.isEmpty) continue;
          if (widget.structures!.length > 1) {
            buffer.writeln('<h3>$section</h3>');
          } else {
            buffer.writeln('<h2>$section</h2>');
          }
          buffer.writeln('<div style="display:flex;flex-wrap:wrap;">');
          for (var photo in photos) {
            final label = photo.label.isNotEmpty ? photo.label : 'Unlabeled';
            final damage =
                photo.damageType.isNotEmpty ? photo.damageType : 'Unknown';
            buffer.writeln('<div style="width:300px;margin:5px;text-align:center;">');
            buffer.writeln('<img src="${photo.url}" width="300" height="300" style="object-fit:cover;"><br>');
            final ts = photo.capturedAt.toLocal().toString().split('.').first;
            String gps = '';
            if (_showGps && photo.latitude != null && photo.longitude != null) {
              gps = '<br><a href="https://www.google.com/maps/search/?api=1&query=${photo.latitude},${photo.longitude}">${photo.latitude!.toStringAsFixed(4)}, ${photo.longitude!.toStringAsFixed(4)}</a>';
            }
            final note = photo.note.isNotEmpty
                ? '<br><em>${photo.note}</em>'
                : '';
            buffer.writeln('<span>$label - $damage<br>$ts$gps$note</span>');
            buffer.writeln('</div>');
          }
          buffer.writeln('</div>');
        }
      }
    }

    buffer.writeln(
        '<p style="text-align: center; margin-top: 40px;">$_contactInfo</p>');
    buffer.writeln(
        '<footer style="text-align:center;margin-top:20px;font-size:12px;color:#666;">$_disclaimerText</footer>');
    buffer.writeln('</body></html>');

    return buffer.toString();
  }

  // HTML download
  void _downloadHtml() {
    final htmlContent = generateHtmlPreview();
    _saveHtmlFile(htmlContent);
    inspectionChecklist.markComplete('Report Exported');
  }

  void _saveHtmlFile(String htmlContent) {
    final bytes = utf8.encode(htmlContent);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final fileName = _metadataFileName('html');
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _openMap(double lat, double lng) {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  pw.Widget _pdfSectionHeader(String text) {
    if (_template == 'modern') {
      return pw.Container(
        color: PdfColor.fromInt(_theme.primaryColor).withOpacity(0.2),
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(_theme.primaryColor))),
      );
    }
    return pw.Text(text,
        style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(_theme.primaryColor)));
  }

  // Helper to load all images before PDF generation
  Future<List<pw.Widget>> _buildPdfWidgets() async {
    final List<pw.Widget> widgets = [];

    Future<pw.Widget> buildWrap(List<PhotoEntry> photos) async {
      final items = <pw.Widget>[];
      for (var photo in photos) {
        final imageData =
            await NetworkAssetBundle(Uri.parse(photo.url)).load("");
        final bytes = imageData.buffer.asUint8List();
        final label = photo.label.isNotEmpty ? photo.label : 'Unlabeled';
        final damage =
            photo.damageType.isNotEmpty ? photo.damageType : 'Unknown';

        items.add(
          pw.Container(
            width: 150,
            child: pw.Column(
              children: [
                pw.Image(pw.MemoryImage(bytes),
                    width: 150, height: 150, fit: pw.BoxFit.cover),
                pw.SizedBox(height: 4),
                pw.Text('$label - $damage',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 12)),
                pw.Text(
                    photo.capturedAt
                        .toLocal()
                        .toString()
                        .split('.').first,
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
                      style: const pw.TextStyle(
                          fontSize: 10, fontStyle: pw.FontStyle.italic)),
              ],
            ),
          ),
        );
      }

      return pw.Wrap(spacing: 10, runSpacing: 10, children: items);
    }

    if (widget.structures != null) {
      for (final struct in widget.structures!) {
        if (widget.structures!.length > 1) {
          widgets.add(_pdfSectionHeader(struct.name));
          widgets.add(pw.SizedBox(height: 10));
        }
        for (var section
            in widget.template?.sections ?? sectionsForType(_metadata.inspectionType)) {
          final photos = struct.sectionPhotos[section] ?? [];
          if (photos.isEmpty) continue;
          widgets.add(_pdfSectionHeader(section));
          widgets.add(pw.SizedBox(height: 8));
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
        pw.Page(
          footer: (context) =>
              pw.Text(_contactInfo, textAlign: pw.TextAlign.center),
          build: (context) => pw.Center(
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
                  _metadata.inspectorRole == InspectorReportRole.adjuster
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
                pw.Text('Inspection Date: ${_metadata.inspectionDate.toLocal().toString().split(' ')[0]}'),
                if (_metadata.insuranceCarrier != null)
                  pw.Text('Insurance Carrier: ${_metadata.insuranceCarrier}'),
                pw.Text('Peril Type: ${_metadata.perilType.name}'),
                pw.Text('Inspection Type: ${_metadata.inspectionType.name}'),
                pw.Text('Inspector Role: ${_metadata.inspectorRole.name.replaceAll('_', ' ')}'),
                if (_metadata.inspectorName != null)
                  pw.Text('Inspector Name: ${_metadata.inspectorName}'),
                pw.SizedBox(height: 20),
                if ((_aiSummary?.status == 'approved' ||
                        _aiSummary?.status == 'edited') &&
                    (_adjusterSummaryController.text.isNotEmpty ||
                        _homeownerSummaryController.text.isNotEmpty))
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration:
                        pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Inspection Summary',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        if (_adjusterSummaryController.text.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text('For Adjuster: ${_adjusterSummaryController.text}'),
                        ],
                        if (_homeownerSummaryController.text.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text('For Homeowner: ${_homeownerSummaryController.text}'),
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
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(_summaryController.text),
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
        ),
      )
      ..addPage(
        pw.MultiPage(
          footer: (context) =>
              pw.Text(_contactInfo, textAlign: pw.TextAlign.center),
          build: (pw.Context context) => [
            pw.Header(level: 0, text: 'ClearSky Photo Report'),
            pw.Text('Client Name: ${_metadata.clientName}'),
            pw.Text('Property Address: ${_metadata.propertyAddress}'),
            pw.Text('Inspection Date: ${_metadata.inspectionDate.toLocal().toString().split(' ')[0]}'),
            if (_metadata.insuranceCarrier != null)
              pw.Text('Insurance Carrier: ${_metadata.insuranceCarrier}'),
            pw.Text('Peril Type: ${_metadata.perilType.name}'),
            pw.Text('Inspection Type: ${_metadata.inspectionType.name}'),
            pw.Text('Inspector Role: ${_metadata.inspectorRole.name.replaceAll('_', ' ')}'),
            if (_metadata.inspectorName != null)
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
                            color: step.isComplete ? PdfColors.black : PdfColors.red)),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      step.requiredPhotos > 0
                          ? '${step.title} (${step.photosTaken}/${step.requiredPhotos})'
                          : step.title,
                      style: pw.TextStyle(
                          color: step.isComplete ? PdfColors.black : PdfColors.red),
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
                  pw.Container(height: 1, width: double.infinity, color: PdfColors.black),
                if (_metadata.inspectorName != null)
                  pw.Text('${_metadata.inspectorName!} – $dateStr'),
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
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      return;
    }

    Directory? dir;
    try {
      dir = await getDownloadsDirectory();
    } catch (_) {
      dir = await getApplicationDocumentsDirectory();
    }
    dir ??= await getApplicationDocumentsDirectory();

    final path = p.join(dir.path, fileName);
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    setState(() => _exportedFile = file);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF exported')),
    );
    inspectionChecklist.markComplete('Report Exported');
  }

  Future<void> _exportZip() async {
    if (widget.savedReport == null || _exporting) return;
    setState(() => _exporting = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
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

  /// Collect report parts into memory for export.
  Future<Map<String, Uint8List>> _collectReportParts() async {
    final files = <String, Uint8List>{};
    final htmlContent = generateHtmlPreview();
    files['report.html'] = Uint8List.fromList(utf8.encode(htmlContent));
    files['report.pdf'] = await _downloadPdf();

    Future<void> addPhotos(String section, List<PhotoEntry> photos) async {
      final sectionClean = section.replaceAll(RegExp(r'\s+'), '');
      for (final photo in photos) {
        try {
          Uint8List bytes;
          if (photo.url.startsWith('http')) {
            final data =
                await NetworkAssetBundle(Uri.parse(photo.url)).load('');
            bytes = data.buffer.asUint8List();
          } else {
            final file = File(photo.url);
            if (!await file.exists()) continue;
            bytes = await file.readAsBytes();
          }
          final label = photo.label.isNotEmpty ? photo.label : 'Unlabeled';
          final cleanLabel =
              label.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
          final name = '${sectionClean}_${cleanLabel}.jpg';
          files[name] = bytes;
        } catch (_) {}
      }
    }

    if (widget.structures != null) {
      for (final struct in widget.structures!) {
        for (final entry in struct.sectionPhotos.entries) {
          final label = widget.structures!.length > 1
              ? '${struct.name} - ${entry.key}'
              : entry.key;
          await addPhotos(label, entry.value);
        }
      }
    }

    return files;
  }

  void _previewFullReport() {
    final htmlContent = generateHtmlPreview();
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Client Name: ${_metadata.clientName}'),
                Text('Property Address: ${_metadata.propertyAddress}'),
                Text('Inspection Date: ${_metadata.inspectionDate.toLocal().toString().split(" ")[0]}'),
                if (_metadata.insuranceCarrier != null)
                  Text('Insurance Carrier: ${_metadata.insuranceCarrier}'),
                Text('Peril Type: ${_metadata.perilType.name}'),
                Text('Inspection Type: ${_metadata.inspectionType.name}'),
                Text('Inspector Role: ${_metadata.inspectorRole.name.replaceAll('_', ' ')}'),
                if (_metadata.inspectorName != null)
                  Text('Inspector Name: ${_metadata.inspectorName}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: widget.readOnly
                ? Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey)),
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
                    decoration: const InputDecoration(
                      labelText: 'Inspector Notes / Summary',
                      border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _summaryField(_adjusterSummaryController, 'Adjuster Summary'),
                const SizedBox(height: 8),
                _summaryField(
                    _homeownerSummaryController, 'Homeowner Summary'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _loadingSummary ? null : _generateSummary,
                      child: const Text('Regenerate'),
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
                            final label =
                                photo.label.isNotEmpty ? photo.label : 'Unlabeled';
                            return Column(
                              children: [
                                AspectRatio(
                                  aspectRatio: 1,
                                  child: Image.network(photo.url, fit: BoxFit.cover),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Column(
                                    children: [
                                      Text(label),
                                      Text(
                                        photo.capturedAt
                                            .toLocal()
                                            .toString()
                                            .split('.').first,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      if (_showGps &&
                                          photo.latitude != null &&
                                          photo.longitude != null)
                                        GestureDetector(
                                          onTap: () => _openMap(photo.latitude!, photo.longitude!),
                                          child: Text(
                                            '${photo.latitude!.toStringAsFixed(4)}, ${photo.longitude!.toStringAsFixed(4)}',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                decoration: TextDecoration.underline),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

