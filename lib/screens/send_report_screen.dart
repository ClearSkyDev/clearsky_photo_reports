import 'package:flutter/material.dart';
import '../models/inspection_metadata.dart';
import '../models/photo_entry.dart';
import '../models/saved_report.dart';
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
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../utils/share_utils.dart';
import 'inspection_checklist_screen.dart';

/// If Firebase is not desired:
/// - Use `path_provider` and `shared_preferences` or `hive` to save report JSON locally
/// - Save photo paths using app directory
/// - Create a LocalReportStore that mirrors the Firestore logic with local files

class SendReportScreen extends StatefulWidget {
  final InspectionMetadata metadata;
  final Map<String, List<PhotoEntry>>? sections;
  final List<Map<String, List<PhotoEntry>>>? additionalStructures;
  final List<String>? additionalNames;
  final String? summary;
  final Uint8List? signature;

  const SendReportScreen({
    super.key,
    required this.metadata,
    this.sections,
    this.additionalStructures,
    this.additionalNames,
    this.summary,
    this.signature,
  });

  @override
  State<SendReportScreen> createState() => _SendReportScreenState();
}

class _SendReportScreenState extends State<SendReportScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _saving = false;
  String? _docId;
  SavedReport? _savedReport;
  bool _exporting = false;
  Uint8List? _signature;
  bool _signatureLocked = false;
  File? _exportedFile;

  @override
  void initState() {
    super.initState();
    _initialize();
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
              damageType: p.damageType));
        } catch (_) {}
      }
      return result;
    }

    final sectionPhotos = <String, List<ReportPhotoEntry>>{};

    if (widget.sections != null) {
      for (var entry in widget.sections!.entries) {
        final uploaded = await uploadSection(entry.key, entry.value);
        if (uploaded.isNotEmpty) {
          sectionPhotos[entry.key] = uploaded;
        }
      }
    }

    if (widget.additionalStructures != null && widget.additionalNames != null) {
      for (int i = 0; i < widget.additionalStructures!.length; i++) {
        final name = widget.additionalNames![i];
        final sections = widget.additionalStructures![i];
        for (var entry in sections.entries) {
          final label = '$name - ${entry.key}';
          final uploaded = await uploadSection(label, entry.value);
          if (uploaded.isNotEmpty) {
            sectionPhotos[label] = uploaded;
          }
        }
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

    final saved = SavedReport(
      id: reportId,
      userId: profile?.id,
      inspectionMetadata: metadataMap,
      sectionPhotos: sectionPhotos,
      summary: widget.summary,
      signature: signatureUrl,
    );

    await doc.set(saved.toMap());

    setState(() {
      _saving = false;
      _docId = reportId;
      _savedReport = saved;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report saved to cloud')),
      );
    }
  }

  Future<void> _reSign() async {
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
    if (_signature == null) return;
    await SignatureStorage.save(_signature!);
    setState(() {
      _signatureLocked = true;
    });
  }

  void _downloadPdf() {
    // TODO: reuse _downloadPdf from ReportPreviewScreen
  }

  void _downloadHtml() {
    // TODO: reuse _saveHtmlFile logic
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
              if (!_signatureLocked) ...[
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
              ],
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
