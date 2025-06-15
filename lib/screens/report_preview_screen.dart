import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show NetworkAssetBundle;
import 'dart:convert';
import '../models/photo_entry.dart';
import 'dart:html' as html; // for HTML download (web only)
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class ReportPreviewScreen extends StatefulWidget {
  final List<PhotoEntry> photos;

  const ReportPreviewScreen({super.key, required this.photos});

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
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

    for (var photo in widget.photos) {
      buffer.writeln('<div style="margin-bottom: 20px;">');
      buffer.writeln('<img src="${photo.url}" width="300"><br>');
      buffer.writeln('<strong>${photo.label}</strong>');
      buffer.writeln('</div>');
    }

    buffer.writeln('</body></html>');

    final htmlContent = buffer.toString();
    _saveHtmlFile(htmlContent);
  }

  void _saveHtmlFile(String htmlContent) {
    final bytes = utf8.encode(htmlContent);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "photo_report.html")
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
            pw.Text(photo.label, style: pw.TextStyle(fontSize: 16)),
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

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(level: 0, text: 'ClearSky Photo Report'),
          ...widgets,
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Report')),
      body: Column(
        children: [
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
                  onPressed: _downloadHtml,
                  child: const Text("Download HTML"),
                ),
                ElevatedButton(
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
