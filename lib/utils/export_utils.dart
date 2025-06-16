import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
// Only used on web to trigger downloads
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/inspection_metadata.dart';
import '../models/inspection_sections.dart';
import '../models/saved_report.dart';

const String _contactInfo =
    'ClearSky Roof Inspectors | www.clearskyroof.com | (555) 123-4567';
const String _disclaimerText =
    'This report is for informational purposes only and is not a warranty.';
const String _coverDisclaimer =
    'This report is a professional opinion based on visual inspection only.';

String _slugify(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

/// Exports [report] as a ZIP archive containing an HTML file, PDF file
/// and a folder of labeled photos. Returns the saved file on mobile.
Future<File?> exportAsZip(SavedReport report) async {
  final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
  final addressSlug = _slugify(meta.propertyAddress);
  final fileName = '${addressSlug}_clearsky_report.zip';
  final htmlStr = await _generateHtml(report);
  final pdfBytes = await _generatePdf(report);

  final archive = Archive();
  final htmlBytes = utf8.encode(htmlStr);
  archive.addFile(ArchiveFile('report.html', htmlBytes.length, htmlBytes));
  archive.addFile(ArchiveFile('report.pdf', pdfBytes.length, pdfBytes));

  for (final struct in report.structures) {
    for (final entry in struct.sectionPhotos.entries) {
      final section = '${struct.name}_${entry.key}'.replaceAll(RegExp(r'\s+'), '');
      for (final photo in entry.value) {
        try {
          final file = File(photo.photoUrl);
          if (!await file.exists()) continue;
          final bytes = await file.readAsBytes();
          final label = photo.label.isNotEmpty ? photo.label : 'Unlabeled';
        final damage =
            photo.damageType.isNotEmpty ? photo.damageType : 'Unknown';
        final damage =
            photo.damageType.isNotEmpty ? photo.damageType : 'Unknown';
        final cleanLabel =
            label.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
        final ext = p.extension(file.path);
        final name = 'photos/${section}_${cleanLabel}$ext';
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      } catch (_) {
        // ignore file errors
      }
      }
    }
  }
  }

  final zipData = ZipEncoder().encode(archive)!;

  if (kIsWeb) {
    final blob = html.Blob([zipData], 'application/zip');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
    return null;
  }

  Directory? dir;
  try {
    dir = await getDownloadsDirectory();
  } catch (_) {
    dir = await getApplicationDocumentsDirectory();
  }
  dir ??= await getApplicationDocumentsDirectory();

  final filePath = p.join(dir.path, fileName);
  final file = File(filePath);
  await file.writeAsBytes(zipData, flush: true);

  final reportFile = File(filePath);
  return reportFile;
}

Future<String> _generateHtml(SavedReport report) async {
  final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString('report_settings');
  bool showGps = true;
  if (data != null) {
    final map = jsonDecode(data) as Map<String, dynamic>;
    showGps = map['showGpsData'] as bool? ?? true;
  }
  final buffer = StringBuffer()
    ..writeln('<html><head><title>Photo Report</title>')
    ..writeln(
        '<style>body{font-family:Arial,sans-serif;} h2{background:#e0e0e0;padding:4px;}</style>')
    ..writeln('</head><body>')
    ..writeln('<h1>Roof Inspection Report</h1>')
    ..writeln('<p><strong>Client Name:</strong> ${meta.clientName}<br>')
    ..writeln('<strong>Property Address:</strong> ${meta.propertyAddress}<br>')
    ..writeln(
        '<strong>Inspection Date:</strong> ${meta.inspectionDate.toLocal().toString().split(' ')[0]}</p>');

  if (meta.insuranceCarrier != null) {
    buffer.writeln('<p><strong>Insurance Carrier:</strong> ${meta.insuranceCarrier}</p>');
  }
  buffer.writeln('<p><strong>Peril Type:</strong> ${meta.perilType.name}</p>');
  if (meta.inspectorName != null) {
    buffer.writeln('<p><strong>Inspector Name:</strong> ${meta.inspectorName}</p>');
  }
  if (report.summaryText != null && report.summaryText!.isNotEmpty) {
    buffer
      ..writeln('<div style="border:1px solid #ccc;padding:8px;margin-top:20px;">')
      ..writeln('<strong>Summary of Findings</strong><br>')
      ..writeln('<p>${report.summaryText}</p>')
      ..writeln('</div>');
  }
  if (report.summary != null && report.summary!.isNotEmpty) {
    buffer
      ..writeln('<div style="border:1px solid #ccc;padding:8px;margin-top:20px;">')
      ..writeln('<strong>Inspector Notes / Summary</strong><br>')
      ..writeln('<p>${report.summary}</p>')
      ..writeln('</div>');
  }
  for (final struct in report.structures) {
    if (report.structures.length > 1) {
      buffer.writeln('<h2>${struct.name}</h2>');
    }
    for (final section in kInspectionSections) {
      final photos = struct.sectionPhotos[section] ?? [];
      if (photos.isEmpty) continue;
      if (report.structures.length > 1) buffer.writeln('<h3>$section</h3>');
      else buffer.writeln('<h2>$section</h2>');
      buffer.writeln('<div style="display:flex;flex-wrap:wrap;">');
      for (final photo in photos) {
        final label = photo.label.isNotEmpty ? photo.label : 'Unlabeled';
        final damage =
            photo.damageType.isNotEmpty ? photo.damageType : 'Unknown';
        buffer
          ..writeln('<div style="width:300px;margin:5px;text-align:center;">')
          ..writeln('<img src="${photo.photoUrl}" width="300" height="300" style="object-fit:cover;"><br>');
        final ts = photo.timestamp?.toLocal().toString().split('.').first ?? '';
        String gps = '';
        if (showGps && photo.latitude != null && photo.longitude != null) {
          gps = '<br><a href="https://www.google.com/maps/search/?api=1&query=${photo.latitude},${photo.longitude}">${photo.latitude!.toStringAsFixed(4)}, ${photo.longitude!.toStringAsFixed(4)}</a>';
        }
        final note = photo.note.isNotEmpty ? '<br><em>${photo.note}</em>' : '';
        buffer
          ..writeln('<span>$label - $damage<br>$ts$gps$note</span>')
          ..writeln('</div>');
      }
      buffer.writeln('</div>');
    }
  }

  buffer
    ..writeln('<p style="text-align: center; margin-top: 40px;">$_contactInfo</p>')
    ..writeln(
        '<footer style="text-align:center;margin-top:20px;font-size:12px;color:#666;">$_disclaimerText</footer>')
    ..writeln('</body></html>');

  return buffer.toString();
}

Future<Uint8List> _generatePdf(SavedReport report) async {
  final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString('report_settings');
  bool showGps = true;
  if (data != null) {
    final map = jsonDecode(data) as Map<String, dynamic>;
    showGps = map['showGpsData'] as bool? ?? true;
  }
  final pdf = pw.Document();

  Future<pw.Widget> buildWrap(List<ReportPhotoEntry> photos) async {
    final items = <pw.Widget>[];
    for (final photo in photos) {
      try {
        final file = File(photo.photoUrl);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
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
                    photo.timestamp?.toLocal().toString().split('.').first ?? '',
                    style: const pw.TextStyle(fontSize: 10)),
                if (showGps && photo.latitude != null && photo.longitude != null)
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
      } catch (_) {}
    }
    return pw.Wrap(spacing: 10, runSpacing: 10, children: items);
  }

  Future<List<pw.Widget>> buildSections() async {
    final widgets = <pw.Widget>[];
    for (final struct in report.structures) {
      if (report.structures.length > 1) {
        widgets.add(_pdfSectionHeader(struct.name));
        widgets.add(pw.SizedBox(height: 10));
      }
      for (final section in kInspectionSections) {
        final photos = struct.sectionPhotos[section] ?? [];
        if (photos.isEmpty) continue;
        widgets.add(_pdfSectionHeader(section));
        widgets.add(pw.SizedBox(height: 8));
        widgets.add(await buildWrap(photos));
        widgets.add(pw.SizedBox(height: 20));
      }
    }
    return widgets;
  }

  final widgets = await buildSections();
  final logoData = await rootBundle.load('assets/images/clearsky_logo.png');
  final logoBytes = logoData.buffer.asUint8List();
  final dateStr = DateTime.now().toLocal().toString().split(' ')[0];
  final summary = report.summary ?? '';
  final summaryText = report.summaryText ?? '';

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
              pw.Text('Roof Inspection Report',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Prepared by ClearSky Roof Inspectors',
                  style: const pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 20),
              pw.Text('Client Name: ${meta.clientName}'),
              pw.Text('Property Address: ${meta.propertyAddress}'),
              pw.Text(
                  'Inspection Date: ${meta.inspectionDate.toLocal().toString().split(' ')[0]}'),
              if (meta.insuranceCarrier != null)
                pw.Text('Insurance Carrier: ${meta.insuranceCarrier}'),
              pw.Text('Peril Type: ${meta.perilType.name}'),
              if (meta.inspectorName != null)
                pw.Text('Inspector Name: ${meta.inspectorName}'),
              pw.SizedBox(height: 20),
              if (summaryText.isNotEmpty)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration:
                      pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Summary of Findings',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(summaryText),
                    ],
                  ),
                ),
              if (summary.isNotEmpty)
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
                      pw.Text(summary),
                    ],
                  ),
                ),
              pw.SizedBox(height: 20),
              pw.Text(_coverDisclaimer,
                  style: const pw.TextStyle(fontSize: 12),
                  textAlign: pw.TextAlign.center),
            ],
          ),
        ),
      ),
    )
    ..addPage(
      pw.MultiPage(
        footer: (context) =>
            pw.Text(_contactInfo, textAlign: pw.TextAlign.center),
        build: (context) => [
          pw.Header(level: 0, text: 'ClearSky Photo Report'),
          pw.Text('Client Name: ${meta.clientName}'),
          pw.Text('Property Address: ${meta.propertyAddress}'),
          pw.Text(
              'Inspection Date: ${meta.inspectionDate.toLocal().toString().split(' ')[0]}'),
          if (meta.insuranceCarrier != null)
            pw.Text('Insurance Carrier: ${meta.insuranceCarrier}'),
          pw.Text('Peril Type: ${meta.perilType.name}'),
          if (meta.inspectorName != null)
            pw.Text('Inspector Name: ${meta.inspectorName}'),
          pw.SizedBox(height: 20),
          ...widgets,
          pw.SizedBox(height: 40),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(height: 1, width: double.infinity, color: PdfColors.black),
              pw.SizedBox(height: 8),
              pw.Text('Inspector Signature'),
              if (meta.inspectorName != null)
                pw.Text('${meta.inspectorName!} – $dateStr'),
            ],
          ),
        ],
      ),
    );

  return pdf.save();
}
