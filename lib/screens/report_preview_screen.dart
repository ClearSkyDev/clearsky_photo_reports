import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle, rootBundle;
import 'dart:convert';
import '../models/photo_entry.dart';
import '../models/inspection_metadata.dart';
import '../models/inspection_sections.dart';
import 'dart:html' as html; // for HTML download (web only)
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'send_report_screen.dart';
import 'report_preview_webview.dart';

class ReportPreviewScreen extends StatefulWidget {
  final List<PhotoEntry>? photos;
  final InspectionMetadata metadata;
  final Map<String, List<PhotoEntry>>? sections;
  final List<Map<String, List<PhotoEntry>>>? additionalStructures;
  final List<String>? additionalNames;
  final bool readOnly;

  const ReportPreviewScreen({
    super.key,
    this.photos,
    this.sections,
    this.additionalStructures,
    this.additionalNames,
    required this.metadata,
    this.readOnly = false,
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

  @override
  void initState() {
    super.initState();
    _metadata = widget.metadata;
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

    if (widget.sections != null) {
      for (var section in kInspectionSections) {
        final photos = widget.sections![section] ?? [];
        if (photos.isNotEmpty) {
          groups.add(MapEntry(section, photos));
        }
      }
    }

    if (widget.additionalStructures != null &&
        widget.additionalNames != null) {
      for (int i = 0; i < widget.additionalStructures!.length; i++) {
        final name = widget.additionalNames![i];
        final sections = widget.additionalStructures![i];
        for (var section in kInspectionSections) {
          final photos = sections[section] ?? [];
          if (photos.isNotEmpty) {
            groups.add(MapEntry('$name - $section', photos));
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
        all.add(PhotoEntry(url: p.url, label: '${group.key}$suffix'));
      }
    }
    return all;
  }

  // Generate the HTML string for the report preview
  String generateHtmlPreview() {
    final buffer = StringBuffer();
    buffer.writeln('<html><head><title>Photo Report</title></head><body>');
    buffer.writeln(
        '<img src="assets/images/clearsky_logo.png" alt="ClearSky Logo" style="width:200px;">');
    buffer.writeln('<h1>ClearSky Photo Report</h1>');
    buffer.writeln('<h2>Inspection Details</h2>');
    buffer.writeln('<p>');
    buffer.writeln('Client Name: ${_metadata.clientName}<br>');
    buffer.writeln('Property Address: ${_metadata.propertyAddress}<br>');
    buffer.writeln(
        'Inspection Date: ${_metadata.inspectionDate.toLocal().toString().split(" ")[0]}<br>');
    if (_metadata.insuranceCarrier != null) {
      buffer.writeln('Insurance Carrier: ${_metadata.insuranceCarrier}<br>');
    }
    buffer.writeln('Peril Type: ${_metadata.perilType.name}<br>');
    if (_metadata.inspectorName != null) {
      buffer.writeln('Inspector Name: ${_metadata.inspectorName}<br>');
    }
    if (_metadata.reportId != null) {
      buffer.writeln('Report ID: ${_metadata.reportId}<br>');
    }
    if (_metadata.weatherNotes != null) {
      buffer.writeln('Weather Notes: ${_metadata.weatherNotes}<br>');
    }
    buffer.writeln('</p>');

    if (widget.sections != null) {
      for (var section in kInspectionSections) {
        final photos = widget.sections![section] ?? [];
        if (photos.isEmpty) continue;
        buffer.writeln('<h2>$section</h2>');
        buffer.writeln('<div style="display:flex;flex-wrap:wrap;">');
        for (var photo in photos) {
          final label = photo.label.isNotEmpty ? photo.label : 'Unlabeled';
          buffer.writeln(
              '<div style="width:300px;margin:5px;text-align:center;">');
          buffer.writeln(
              '<img src="${photo.url}" width="300" height="300" style="object-fit:cover;"><br>');
          buffer.writeln('<span>$label</span>');
          buffer.writeln('</div>');
        }
        buffer.writeln('</div>');
      }
    }

    if (widget.additionalStructures != null && widget.additionalNames != null) {
      for (int i = 0; i < widget.additionalStructures!.length; i++) {
        final name = widget.additionalNames![i];
        final sections = widget.additionalStructures![i];
        buffer.writeln('<h2>$name</h2>');
        for (var section in kInspectionSections) {
          final photos = sections[section] ?? [];
          if (photos.isEmpty) continue;
          buffer.writeln('<h3>$section</h3>');
          buffer.writeln('<div style="display:flex;flex-wrap:wrap;">');
          for (var photo in photos) {
            final label = photo.label.isNotEmpty ? photo.label : 'Unlabeled';
            buffer.writeln(
                '<div style="width:300px;margin:5px;text-align:center;">');
            buffer.writeln(
                '<img src="${photo.url}" width="300" height="300" style="object-fit:cover;"><br>');
            buffer.writeln('<span>$label</span>');
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

        items.add(
          pw.Container(
            width: 150,
            child: pw.Column(
              children: [
                pw.Image(pw.MemoryImage(bytes),
                    width: 150, height: 150, fit: pw.BoxFit.cover),
                pw.SizedBox(height: 4),
                pw.Text(label,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      }

      return pw.Wrap(spacing: 10, runSpacing: 10, children: items);
    }

    if (widget.sections != null) {
      for (var section in kInspectionSections) {
        final photos = widget.sections![section] ?? [];
        if (photos.isEmpty) continue;
        widgets.add(pw.Text(section,
            style: pw.TextStyle(
                fontSize: 18, fontWeight: pw.FontWeight.bold)));
        widgets.add(pw.SizedBox(height: 8));
        widgets.add(await buildWrap(photos));
        widgets.add(pw.SizedBox(height: 20));
      }
    }

    if (widget.additionalStructures != null && widget.additionalNames != null) {
      for (int i = 0; i < widget.additionalStructures!.length; i++) {
        final name = widget.additionalNames![i];
        final sections = widget.additionalStructures![i];
        widgets.add(pw.Text(name,
            style: pw.TextStyle(
                fontSize: 20, fontWeight: pw.FontWeight.bold)));
        widgets.add(pw.SizedBox(height: 10));
        for (var section in kInspectionSections) {
          final photos = sections[section] ?? [];
          if (photos.isEmpty) continue;
          widgets.add(pw.Text(section,
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold)));
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(await buildWrap(photos));
          widgets.add(pw.SizedBox(height: 20));
        }
      }
    }

    return widgets;
  }

  // PDF export
  Future<void> _downloadPdf() async {
    final pdf = pw.Document();
    final widgets = await _buildPdfWidgets();

    final logoData = await rootBundle.load('assets/images/clearsky_logo.png');
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
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Prepared by ClearSky Roof Inspectors',
                  style: const pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Client Name: ${_metadata.clientName}'),
                pw.Text('Property Address: ${_metadata.propertyAddress}'),
                pw.Text('Inspection Date: ${_metadata.inspectionDate.toLocal().toString().split(' ')[0]}'),
                if (_metadata.insuranceCarrier != null)
                  pw.Text('Insurance Carrier: ${_metadata.insuranceCarrier}'),
                pw.Text('Peril Type: ${_metadata.perilType.name}'),
                if (_metadata.inspectorName != null)
                  pw.Text('Inspector Name: ${_metadata.inspectorName}'),
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
            if (_metadata.inspectorName != null)
              pw.Text('Inspector Name: ${_metadata.inspectorName}'),
            pw.SizedBox(height: 20),
            ...widgets,
          ],
        ),
      );

    final fileName = _metadataFileName('pdf');
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: fileName,
    );
  }

  void _previewFullReport() {
    final htmlContent = generateHtmlPreview();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewWebView(
          html: htmlContent,
          onExportPdf: _downloadPdf,
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
                if (_metadata.inspectorName != null)
                  Text('Inspector Name: ${_metadata.inspectorName}'),
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
                                  child: Text(label),
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
                  onPressed: _downloadPdf,
                  child: const Text("Download PDF"),
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
                        sections: widget.sections,
                        additionalStructures: widget.additionalStructures,
                        additionalNames: widget.additionalNames,
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
