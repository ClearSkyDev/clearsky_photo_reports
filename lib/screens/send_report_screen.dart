import 'package:flutter/material.dart';
import '../models/inspection_metadata.dart';
import '../models/photo_entry.dart';
import '../models/saved_report.dart';
import '../models/inspected_structure.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import '../utils/signature_storage.dart';
import 'capture_signature_screen.dart';
import '../utils/local_report_store.dart';
import '../utils/export_utils.dart';
import '../utils/profile_storage.dart';
import '../models/checklist.dart';
import '../utils/summary_utils.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../utils/share_utils.dart';
import 'inspection_checklist_screen.dart';
import 'photo_map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/report_theme.dart';
import '../utils/photo_audit.dart';

/// If Firebase is not desired:
/// - Use `path_provider` and `shared_preferences` or `hive` to save report JSON locally
/// - Save photo paths using app directory
/// - Create a LocalReportStore that mirrors the Firestore logic with local files

class SendReportScreen extends StatefulWidget {
  final InspectionMetadata metadata;
  final List<InspectedStructure>? structures;
  final String? summary;
  final String? summaryText;
  final Uint8List? signature;

  const SendReportScreen({
    super.key,
    required this.metadata,
    this.structures,
    this.summary,
    this.summaryText,
    this.signature,
  });

  @override
  State<SendReportScreen> createState() => _SendReportScreenState();
}

class _SendReportScreenState extends State<SendReportScreen> {
  final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _summaryTextController;
  bool _saving = false;
  String? _docId;
  SavedReport? _savedReport;
  bool _exporting = false;
  Uint8List? _signature;
  bool _signatureLocked = false;
  File? _exportedFile;
  bool _finalized = false;
  String? _publicId;
  bool? _auditPassed;
  List<PhotoAuditIssue> _auditIssues = [];

  List<PhotoEntry> _gpsPhotos() {
    final result = <PhotoEntry>[];
    if (widget.structures != null) {
      for (final struct in widget.structures!) {
        for (var photos in struct.sectionPhotos.values) {
          for (var p in photos) {
            if (p.latitude != null && p.longitude != null) {
              result.add(p);
            }
          }
        }
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _summaryTextController =
        TextEditingController(text: widget.summaryText ?? '');
    _initialize();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _summaryTextController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    _signature = widget.signature ?? await SignatureStorage.load();
    await _saveReport();
  }

  Future<void> _saveReport() async {
    if (_saving) return;
    setState(() => _saving = true);

    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    final doc = firestore.collection('reports').doc();
    final reportId = doc.id;
    final profile = await ProfileStorage.load();

    Future<List<ReportPhotoEntry>> uploadSection(
        String section, List<PhotoEntry> photos) async {
      final result = <ReportPhotoEntry>[];
      for (var i = 0; i < photos.length; i++) {
        final p = photos[i];
        try {
          final file = File(p.url);
          final ref = storage
              .ref()
              .child('reports/$reportId/$section/photo_$i.jpg');
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          result.add(ReportPhotoEntry(
              label: p.label,
              photoUrl: url,
              timestamp: p.capturedAt,
              latitude: p.latitude,
              longitude: p.longitude,
              damageType: p.damageType,
              note: p.note));
        } catch (_) {}
      }
      return result;
    }

    final structs = <InspectedStructure>[];

    if (widget.structures != null) {
      for (final struct in widget.structures!) {
        final uploadedSections = <String, List<ReportPhotoEntry>>{};
        for (var entry in struct.sectionPhotos.entries) {
          final uploaded = await uploadSection('${struct.name}/${entry.key}', entry.value);
          if (uploaded.isNotEmpty) {
            uploadedSections[entry.key] = uploaded;
          }
        }
        structs.add(InspectedStructure(name: struct.name, sectionPhotos: uploadedSections));
      }
    }

    String? signatureUrl;
    if (_signature != null) {
      try {
        final ref =
            storage.ref().child('reports/$reportId/signature.png');
        await ref.putData(_signature!,
            SettableMetadata(contentType: 'image/png'));
        signatureUrl = await ref.getDownloadURL();
      } catch (_) {}
    }

    final metadataMap = {
      'clientName': widget.metadata.clientName,
      'propertyAddress': widget.metadata.propertyAddress,
      'inspectionDate':
          widget.metadata.inspectionDate.toIso8601String(),
      if (widget.metadata.insuranceCarrier != null)
        'insuranceCarrier': widget.metadata.insuranceCarrier,
      'perilType': widget.metadata.perilType.name,
      if (profile?.name != null)
        'inspectorName': profile!.name
      else if (widget.metadata.inspectorName != null)
        'inspectorName': widget.metadata.inspectorName,
      if (widget.metadata.reportId != null)
        'reportId': widget.metadata.reportId,
      if (widget.metadata.weatherNotes != null)
        'weatherNotes': widget.metadata.weatherNotes,
    };

    final prefs = await SharedPreferences.getInstance();
    ReportTheme theme = ReportTheme.defaultTheme;
    final themeData = prefs.getString('report_theme');
    if (themeData != null) {
      theme = ReportTheme.fromMap(jsonDecode(themeData) as Map<String, dynamic>);
    }

    final saved = SavedReport(
      id: reportId,
      userId: profile?.id,
      inspectionMetadata: metadataMap,
      structures: structs,
      summary: widget.summary,
      summaryText: _summaryTextController.text,
      signature: signatureUrl,
      theme: theme,
      lastAuditPassed: null,
      lastAuditIssues: null,
    );

    await doc.set(saved.toMap());

    setState(() {
      _saving = false;
      _docId = reportId;
      _savedReport = saved;
      _finalized = saved.isFinalized;
      _publicId = saved.publicReportId;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report saved to cloud')),
      );
    }
  }

  Future<void> _reSign() async {
    if (_finalized) return;
    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => const CaptureSignatureScreen()),
    );
    if (result != null) {
      setState(() {
        _signature = result;
        _signatureLocked = false;
      });
    }
  }

  Future<void> _lockSignature() async {
    if (_signature == null || _finalized) return;
    await SignatureStorage.save(_signature!);
    setState(() {
      _signatureLocked = true;
    });
  }

  String get _publicUrl => 'https://clearskyroof.com/reports/$_publicId';

  Future<void> _copyLink() async {
    if (_publicId == null) return;
    await Clipboard.setData(ClipboardData(text: _publicUrl));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Link copied')));
    }
  }

  void _openLink() {
    if (_publicId == null) return;
    final uri = Uri.parse(_publicUrl);
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _autoGenerateSummary() {
    final metaMap = {
      'clientName': widget.metadata.clientName,
      'propertyAddress': widget.metadata.propertyAddress,
      'inspectionDate': widget.metadata.inspectionDate.toIso8601String(),
      if (widget.metadata.insuranceCarrier != null)
        'insuranceCarrier': widget.metadata.insuranceCarrier,
      'perilType': widget.metadata.perilType.name,
      if (widget.metadata.inspectorName != null)
        'inspectorName': widget.metadata.inspectorName,
      if (widget.metadata.reportId != null)
        'reportId': widget.metadata.reportId,
      if (widget.metadata.weatherNotes != null)
        'weatherNotes': widget.metadata.weatherNotes,
    };
    final report = SavedReport(
      inspectionMetadata: metaMap,
      structures: widget.structures ?? [],
      summary: widget.summary,
      summaryText: _summaryTextController.text,
    );
    final text = generateSummaryText(report);
    setState(() {
      _summaryTextController.text = text;
      if (_savedReport != null) {
        _savedReport = SavedReport(
          id: _savedReport!.id,
          userId: _savedReport!.userId,
          inspectionMetadata: _savedReport!.inspectionMetadata,
          structures: _savedReport!.structures,
          summary: _savedReport!.summary,
          summaryText: text,
          signature: _savedReport!.signature,
          createdAt: _savedReport!.createdAt,
          isFinalized: _savedReport!.isFinalized,
          publicReportId: _savedReport!.publicReportId,
          lastAuditPassed: _savedReport!.lastAuditPassed,
          lastAuditIssues: _savedReport!.lastAuditIssues,
        );
      }
    });
  }

  void _downloadPdf() {
    // TODO: reuse _downloadPdf from ReportPreviewScreen
  }

  void _downloadHtml() {
    // TODO: reuse _saveHtmlFile logic
  }

  Future<void> _exportCsv() async {
    if (_savedReport == null || _exporting) return;
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
      final file = await exportCsv(_savedReport!);
      if (mounted) {
        setState(() => _exportedFile = file);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exported')),
        );
      }
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportZip() async {
    if (_savedReport == null || _exporting) return;
    if (!inspectionChecklist.allComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all checklist steps first')),
      );
      return;
    }
    setState(() => _exporting = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 60,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
    try {
      final file = await exportAsZip(_savedReport!);
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

  Future<void> _runAudit() async {
    if (_savedReport == null) return;
    final result = await photoAudit(_savedReport!);
    if (_docId != null) {
      try {
        await FirebaseFirestore.instance.collection('reports').doc(_docId).update({
          'lastAuditPassed': result.passed,
          'lastAuditIssues': result.issues.map((e) => e.toMap()).toList(),
        });
      } catch (_) {}
    }
    setState(() {
      _auditPassed = result.passed;
      _auditIssues = result.issues;
    });
    _showAuditDialog();
  }

  void _showAuditDialog() {
    if (_auditPassed == null) return;
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(_auditPassed! ? 'Audit Passed' : 'Audit Issues'),
          content: _auditPassed!
              ? const Text('No issues found.')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _auditIssues.length,
                    itemBuilder: (context, index) {
                      final issue = _auditIssues[index];
                      return ListTile(
                        leading: Image.network(issue.photo.photoUrl,
                            width: 56, height: 56, fit: BoxFit.cover),
                        title: Text(issue.issue),
                        subtitle: Text('${issue.structure} - ${issue.section}'),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareReport() async {
    if (_exportedFile == null) return;
    final m = widget.metadata;
    final subject = 'Roof Inspection Report for ${m.clientName}';
    final inspector = m.inspectorName != null ? ' by ${m.inspectorName}' : '';
    final body = 'Attached is the roof inspection report for ${m.clientName}$inspector.';
    await shareReportFile(_exportedFile!, subject: subject, text: body);
  }

  Future<void> _sendEmail() async {
    if (_emailController.text.isEmpty) return;
    // TODO: call sendReportByEmail
  }

  Future<void> _finalizeReport() async {
    if (_savedReport == null || _finalized) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalize Report'),
        content: const Text(
            'Lock this report and prevent any further edits?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalize'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    String publicId = FirebaseFirestore.instance.collection('publicReports').doc().id;
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(_docId)
          .update({
            'isFinalized': true,
            'publicReportId': publicId,
            'summaryText': _summaryTextController.text
          });
    } catch (_) {}

    setState(() {
      _finalized = true;
      _publicId = publicId;
      if (_savedReport != null) {
        _savedReport = SavedReport(
          id: _savedReport!.id,
          userId: _savedReport!.userId,
          inspectionMetadata: _savedReport!.inspectionMetadata,
          structures: _savedReport!.structures,
          summary: _savedReport!.summary,
          summaryText: _summaryTextController.text,
          signature: _savedReport!.signature,
          createdAt: _savedReport!.createdAt,
          isFinalized: true,
          publicReportId: publicId,
          lastAuditPassed: _savedReport!.lastAuditPassed,
          lastAuditIssues: _savedReport!.lastAuditIssues,
        );
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report finalized')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metadata;
    return Scaffold(
      appBar: AppBar(title: const Text('Send Report')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_finalized)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.redAccent,
                child: const Text(
                  'FINALIZED',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client: ${m.clientName}'),
                    Text('Address: ${m.propertyAddress}'),
                    Text('Date: ${m.inspectionDate.toLocal().toString().split(' ')[0]}'),
                    if (widget.summary != null && widget.summary!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Inspector Notes / Summary:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(widget.summary!),
                    ],
                  ],
                ),
              ),
            ),
            if (_signature != null) ...[
              const SizedBox(height: 12),
              Image.memory(_signature!, height: 100),
              if (!_signatureLocked && !_finalized) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _reSign,
                      child: const Text('Re-sign'),
                    ),
                    ElevatedButton(
                      onPressed: _lockSignature,
                      child: const Text('Use This Signature'),
                    ),
                  ],
                ),
              ],
            ],
            TextField(
              controller: _summaryTextController,
              decoration: const InputDecoration(
                  labelText: 'Summary of Findings'),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _autoGenerateSummary,
              child: const Text('Auto-Generate'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Client Email'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    onPressed: _downloadPdf,
                    child: const Text('Download PDF')),
                ElevatedButton(
                    onPressed: _downloadHtml,
                    child: const Text('Download HTML')),
                ElevatedButton(
                    onPressed: _exporting ? null : _exportCsv,
                    child: _exporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Export CSV')),
                ElevatedButton(
                    onPressed: _exporting ? null : _exportZip,
                    child: _exporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Export ZIP')),
              if (_exportedFile != null)
                ElevatedButton(
                    onPressed: _shareReport,
                    child: const Text('Share Report')),
              ElevatedButton(
                  onPressed: _runAudit,
                  child: const Text('Run Audit')),
              ],
            ),
            if (_gpsPhotos().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ElevatedButton(
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
              ),
            if (_finalized && _publicId != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Client Share Link',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Center(
                        child: QrImage(
                          data: _publicUrl,
                          size: 160,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(_publicUrl, textAlign: TextAlign.center),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _copyLink,
                            icon: const Icon(Icons.copy),
                          ),
                          IconButton(
                            onPressed: _openLink,
                            icon: const Icon(Icons.open_in_browser),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (!_finalized)
              ElevatedButton(
                onPressed: _finalizeReport,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('Finalize & Lock Report'),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InspectionChecklistScreen(),
                ),
              ),
              child: const Text('View Checklist'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _emailController.text.isEmpty ? null : _sendEmail,
              child: const Text('Send via Email'),
            ),
          ],
        ),
      ),
    );
  }
}
