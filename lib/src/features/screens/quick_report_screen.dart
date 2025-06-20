import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/models/saved_report.dart';
import '../../core/models/inspected_structure.dart';
import '../../core/utils/summary_utils.dart';
import '../../core/utils/export_utils.dart';
import '../../core/utils/share_utils.dart';
import '../../core/utils/export_log.dart';
import '../../core/models/export_log_entry.dart';

class QuickReportScreen extends StatefulWidget {
  const QuickReportScreen({super.key});

  @override
  State<QuickReportScreen> createState() => _QuickReportScreenState();
}

class _QuickReportScreenState extends State<QuickReportScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _addressController = TextEditingController();
  final List<ReportPhotoEntry?> _photos = List.filled(4, null);
  final List<String> _labels = [
    'Address Photo',
    'Front Elevation',
    'Roof Edge',
    'Roof Slopes'
  ];
  int _step = 0;
  String? _summary;
  bool _loadingSummary = false;
  bool _exporting = false;
  bool _includeTestSquare = true;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    setState(() {
      _photos[_step] = ReportPhotoEntry(
        label: _labels[_step],
        caption: '',
        confidence: 0,
        photoUrl: image.path,
        timestamp: DateTime.now(),
      );
    });
  }

  Future<void> _next() async {
    if (_photos[_step] == null) {
      await _pick();
      if (_photos[_step] == null) return;
    }
    if (_step < 3) {
      setState(() => _step++);
    } else if (_step == 3) {
      setState(() => _step++);
      _generateSummary();
    }
  }

  Future<void> _generateSummary() async {
    setState(() => _loadingSummary = true);
    final struct = InspectedStructure(
        name: 'Main Structure',
        address: _addressController.text,
        sectionPhotos: {
          for (var i = 0; i < _labels.length; i++)
            _labels[i]: _photos[i] != null ? [_photos[i]!] : []
        },
        slopeTestSquare: {
          'Roof Slopes': _includeTestSquare
        });
    final metadata = {
      'clientName': '',
      'propertyAddress': _addressController.text,
      'inspectionDate': DateTime.now().toIso8601String(),
      'perilType': 'wind',
      'inspectionType': 'residentialRoof',
      'inspectorRoles': ['ladderAssist'],
    };
    final report = SavedReport(
      inspectionMetadata: metadata,
      structures: [struct],
    );
    final text = generateSummaryText(report);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() {
      _summary = text;
      _loadingSummary = false;
    });
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    final struct = InspectedStructure(
      name: 'Main Structure',
      address: _addressController.text,
      sectionPhotos: {
        for (var i = 0; i < _labels.length; i++)
          _labels[i]: _photos[i] != null ? [_photos[i]!] : []
      },
      slopeTestSquare: {'Roof Slopes': _includeTestSquare},
    );
    final metadata = {
      'clientName': '',
      'propertyAddress': _addressController.text,
      'inspectionDate': DateTime.now().toIso8601String(),
      'perilType': 'wind',
      'inspectionType': 'residentialRoof',
      'inspectorRoles': ['ladderAssist'],
    };
    final report = SavedReport(
      inspectionMetadata: metadata,
      structures: [struct],
      summary: _summary,
    );
    final pdfBytes = await generatePdf(report);
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'quick_report.pdf'));
    await file.writeAsBytes(pdfBytes);
    await shareReportFile(file, subject: 'Quick Report');
    await ExportLog.addEntry(ExportLogEntry(
      reportName: _addressController.text,
      type: 'pdf',
      wasOffline: false,
    ));
    setState(() => _exporting = false);
  }

  Widget _buildStep() {
    if (_step < 4) {
      final label = _labels[_step];
      final photo = _photos[_step];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_step == 0)
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Property Address'),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.camera_alt),
            label: Text(photo == null ? 'Capture $label' : 'Retake $label'),
          ),
          if (photo != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Image.file(File(photo.photoUrl), height: 200),
            ),
          if (label == 'Roof Slopes')
            SwitchListTile(
              title: const Text('Include Test Square?'),
              value: _includeTestSquare,
              onChanged: (v) => setState(() => _includeTestSquare = v),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: _next,
            child: const Text('Next'),
          ),
        ],
      );
    } else if (_step == 4) {
      if (_loadingSummary) {
        return const Center(child: CircularProgressIndicator());
      }
      final controller = TextEditingController(text: _summary ?? '');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            onChanged: (val) => _summary = val,
            decoration: const InputDecoration(labelText: 'Summary'),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => setState(() => _step++),
            child: const Text('Continue to Export'),
          ),
        ],
      );
    } else {
      if (_exporting) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: ElevatedButton(
          onPressed: _export,
          child: const Text('Export PDF'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quick Report')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildStep(),
      ),
    );
  }
}
