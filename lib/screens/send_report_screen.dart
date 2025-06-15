import 'package:flutter/material.dart';
import '../models/inspection_metadata.dart';
import '../models/photo_entry.dart';
import '../models/saved_report.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../utils/local_report_store.dart';

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

  const SendReportScreen({
    super.key,
    required this.metadata,
    this.sections,
    this.additionalStructures,
    this.additionalNames,
    this.summary,
  });

  @override
  State<SendReportScreen> createState() => _SendReportScreenState();
}

class _SendReportScreenState extends State<SendReportScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _saving = false;
  String? _docId;

  @override
  void initState() {
    super.initState();
    // Save the report as soon as this screen is opened
    _saveReport();
  }

  Future<void> _saveReport() async {
    if (_saving) return;
    setState(() => _saving = true);

    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    final doc = firestore.collection('reports').doc();
    final reportId = doc.id;

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
              label: p.label, photoUrl: url, timestamp: DateTime.now()));
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

    final metadataMap = {
      'clientName': widget.metadata.clientName,
      'propertyAddress': widget.metadata.propertyAddress,
      'inspectionDate':
          widget.metadata.inspectionDate.toIso8601String(),
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

    final saved = SavedReport(
      id: reportId,
      userId: null,
      inspectionMetadata: metadataMap,
      sectionPhotos: sectionPhotos,
      summary: widget.summary,
    );

    await doc.set(saved.toMap());

    setState(() {
      _saving = false;
      _docId = reportId;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report saved to cloud')),
      );
    }
  }

  void _downloadPdf() {
    // TODO: reuse _downloadPdf from ReportPreviewScreen
  }

  void _downloadHtml() {
    // TODO: reuse _saveHtmlFile logic
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
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Client Email'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _downloadPdf, child: const Text('Download PDF')),
                ElevatedButton(onPressed: _downloadHtml, child: const Text('Download HTML')),
              ],
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
