import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle, rootBundle;
import 'dart:convert';
import '../models/photo_entry.dart';
import '../models/inspection_metadata.dart';
import 'dart:html' as html; // for HTML download (web only)
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class ReportPreviewScreen extends StatefulWidget {
  final List<PhotoEntry> photos;
  final InspectionMetadata metadata;

  const ReportPreviewScreen({
    super.key,
    required this.photos,
    required this.metadata,
  });

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  static const String _contactInfo =
      'ClearSky Roof Inspectors | www.clearskyroof.com | (555) 123-4567';
  late final InspectionMetadata _metadata;

  @override
  void initState() {
    super.initState();
    _metadata = widget.metadata;
  }
  String _timestampedFileName(String ext) {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    return 'clearsky_report_${y}${m}${d}_${h}${min}.$ext';
  }
  void _updateLabel(int index, String value) {
    setState(() {
      widget.photos[index].label = value;
    });
  }

  // HTML download
  void _downloadHtml() {
    final buffer = StringBuffer();
    buffer.writeln('<html><head><title>Photo Report</title></head><body>');
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
    buffer.writeln('</p>');

    for (var photo in widget.photos) {
      buffer.writeln('<div style="margin-bottom: 20px;">');
      buffer.writeln('<img src="${photo.url}" width="300"><br>');
      buffer.writeln('<strong>${photo.label}</strong>');
      buffer.writeln('</div>');
    }

    buffer.writeln(
        '<p style="text-align: center; margin-top: 40px;">$_contactInfo</p>');
    buffer.writeln('</body></html>');

    final htmlContent = buffer.toString();
    _saveHtmlFile(htmlContent);
  }

  void _saveHtmlFile(String htmlContent) {
    final bytes = utf8.encode(htmlContent);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", _timestampedFileName('html'))
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // Helper to load all images before PDF generation
  Future<List<pw.Widget>> _buildPdfWidgets() async {
    List<pw.Widget> widgets = [];

    for (var photo in widget.photos) {
      final imageData = await NetworkAssetBundle(Uri.parse(photo.url)).load("");
      final bytes = imageData.buffer.asUint8List();

      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(photo.label, style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 5),
            pw.Image(pw.MemoryImage(bytes), width: 300),
            pw.SizedBox(height: 20),
          ],
        ),
      );
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
                pw.SizedBox(height: 10),
                pw.Text(dateStr, style: const pw.TextStyle(fontSize: 14)),
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

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: _timestampedFileName('pdf'),
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
            child: ListView.builder(
              itemCount: widget.photos.length,
              itemBuilder: (context, index) {
                final photo = widget.photos[index];
                final controller = TextEditingController(text: photo.label);
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Image.network(photo.url),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Label'),
                          controller: controller,
                          onChanged: (value) => _updateLabel(index, value),
                        ),
                      ),
                    ],
                  ),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
        ],
      ),
    );
  }
}
