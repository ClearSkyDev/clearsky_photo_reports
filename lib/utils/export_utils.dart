import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
// Only used on web to trigger downloads
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../services/invoice_service.dart';
import 'label_utils.dart';
import '../utils/invoice_pdf.dart';

import '../models/report_theme.dart';

import '../models/inspection_metadata.dart';
import '../models/inspection_type.dart';
import '../models/inspection_sections.dart';
import '../models/saved_report.dart';
import '../models/photo_entry.dart';

Future<void> generateAndDownloadPdf(
  List<PhotoEntry> photos,
  String summary,
) async {
  // Placeholder implementation using simple PDF with summary text
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      build: (context) => pw.Column(
        children: [
          pw.Text(summary),
          pw.SizedBox(height: 20),
          for (final p in photos)
            pw.Text(p.label, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    ),
  );
  final bytes = await pdf.save();
  if (kIsWeb) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'report.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  } else {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'report.pdf'));
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)]);
  }
}

Future<void> generateAndDownloadHtml(
  List<PhotoEntry> photos,
  String summary,
) async {
  final buffer = StringBuffer()
    ..writeln('<html><body>')
    ..writeln('<p>$summary</p>');
  for (final p in photos) {
    buffer.writeln('<p>${p.label}</p>');
    buffer.writeln('<img src="${p.url}" width="300">');
  }
  buffer.writeln('</body></html>');
  final htmlStr = buffer.toString();
  final bytes = utf8.encode(htmlStr);
  if (kIsWeb) {
    final blob = html.Blob([bytes], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'report.html')
      ..click();
    html.Url.revokeObjectUrl(url);
  } else {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'report.html'));
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)]);
  }
}

const String _contactInfo =
    'ClearSky Roof Inspectors | www.clearskyroof.com | (555) 123-4567';
const String _disclaimerText =
    '⚠️ AI-Assisted Report Disclaimer\nThis report was created using AI-assisted tools provided by ClearSky. The information within was input by the inspector and is their sole responsibility. ClearSky does not assume responsibility for any incorrect, incomplete, or misleading information submitted by users. Final coverage decisions should always be made by licensed professionals or carriers.';
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
  final csvStr = generateCsv(report);

  final archive = Archive();
  final htmlBytes = utf8.encode(htmlStr);
  archive.addFile(ArchiveFile('report.html', htmlBytes.length, htmlBytes));
  archive.addFile(ArchiveFile('report.pdf', pdfBytes.length, pdfBytes));
  final csvBytes = utf8.encode(csvStr);
  archive.addFile(ArchiveFile('report.csv', csvBytes.length, csvBytes));

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
        final name = 'photos/${section}_$cleanLabel$ext';
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      } catch (_) {
        // ignore file errors
      }
      }
    }
  }
  return null;
  }

  final zipData = ZipEncoder().encode(archive);

  Null if (kIsWeb) {
    final blob = html.Blob([zipData], 'application/zip');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
    return null;
  }

  Directory? dir;
  void try {
    dir = await getDownloadsDirectory();
  } void catch (_) {
    dir = await getApplicationDocumentsDirectory();
  }
  dir ??= await getApplicationDocumentsDirectory();

  final filePath = p.join(dir.path, fileName);
  final file = File(filePath);
  await file.writeAsBytes(zipData, flush = true);

  final reportFile = File(filePath);
  return reportFile;
}

/// Exports the finalized report as a ZIP file containing the PDF and
/// all labeled photos. When running on the web, the ZIP is uploaded to
/// Firebase Storage and the download URL is opened in a new tab.
Future<File?> exportFinalZip(SavedReport report,
    {bool organizeBySection = true}) async {
  final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
  final addressSlug = _slugify(meta.propertyAddress);
  final fileName = '${addressSlug}_clearsky.zip';

  final pdfBytes = await _generatePdf(report);

  final archive = Archive();
  archive.addFile(ArchiveFile('report.pdf', pdfBytes.length, pdfBytes));

  for (final struct in report.structures) {
    for (final entry in struct.sectionPhotos.entries) {
      final photos = entry.value.where((p) => p.label.isNotEmpty).toList();
      if (photos.isEmpty) continue;
      final sectionFolder =
          '${struct.name}_${entry.key}'.replaceAll(RegExp(r'\s+'), '');
      for (final photo in photos) {
        try {
          Uint8List bytes;
          if (photo.photoUrl.startsWith('http')) {
            final resp = await http.get(Uri.parse(photo.photoUrl));
            if (resp.statusCode != 200) continue;
            bytes = resp.bodyBytes;
          } else {
            final file = File(photo.photoUrl);
            if (!await file.exists()) continue;
            bytes = await file.readAsBytes();
          }
          final label = photo.label.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
          final ext = p.extension(photo.photoUrl);
          final name = organizeBySection
              ? 'photos/$sectionFolder/$label$ext'
              : 'photos/${label}_$sectionFolder$ext';
          archive.addFile(ArchiveFile(name, bytes.length, bytes));
        } catch (_) {}
      }
    }
  }

  final zipData = ZipEncoder().encode(archive);

  if (kIsWeb) {
    final storage = FirebaseStorage.instance;
    final ref = storage.ref().child('report_zips/${report.id}/$fileName');
    await ref.putData(Uint8List.fromList(zipData),
        SettableMetadata(contentType: 'application/zip'));
    final url = await ref.getDownloadURL();
    try {
      await FirebaseFirestore.instance.collection('downloads').add({
        'reportId': report.id,
        'timestamp': Timestamp.now(),
        'type': 'zip',
      });
    } catch (_) {}
    html.AnchorElement(href: url)
      ..target = '_blank'
      ..click();
    return null;
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
  await file.writeAsBytes(zipData, flush: true);

  try {
    await FirebaseFirestore.instance.collection('downloads').add({
      'reportId': report.id,
      'timestamp': Timestamp.now(),
      'type': 'zip',
    });
  } catch (_) {}

  return file;
}

/// Export a legal copy of [report] including metadata, summary,
/// invoice and labeled photos. If running on web or [auto] is true,
/// the ZIP is uploaded to Firebase Storage and a Firestore record is
/// created with the download link.
Future<File?> exportLegalCopy(SavedReport report,
    {String? userId, bool auto = false}) async {
  final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
  final clientSlug = _slugify(meta.clientName);
  final date = meta.inspectionDate.toLocal().toString().split(' ')[0];
  final fileName = '${clientSlug}_${date}_legal.zip';

  final pdfBytes = await _generatePdf(report);

  final archive = Archive();
  archive.addFile(ArchiveFile('report.pdf', pdfBytes.length, pdfBytes));

  final metaJson = jsonEncode(report.toMap());
  archive.addFile(
      ArchiveFile('metadata.json', metaJson.length, utf8.encode(metaJson)));

  if (report.summaryText != null && report.summaryText!.isNotEmpty) {
    final bytes = utf8.encode(report.summaryText!);
    archive.addFile(ArchiveFile('summary.txt', bytes.length, bytes));
  }
  if (report.summary != null && report.summary!.isNotEmpty) {
    final bytes = utf8.encode(report.summary!);
    archive.addFile(ArchiveFile('notes.txt', bytes.length, bytes));
  }

  final invoice = await InvoiceService().fetchInvoiceForReport(report.id);
  if (invoice != null) {
    final invPdf = await generateInvoicePdf(invoice);
    archive.addFile(ArchiveFile('invoice.pdf', invPdf.length, invPdf));
  }

  for (final struct in report.structures) {
    for (final entry in struct.sectionPhotos.entries) {
      final photos = entry.value.where((p) => p.label.isNotEmpty).toList();
      if (photos.isEmpty) continue;
      final sectionFolder =
          '${struct.name}_${entry.key}'.replaceAll(RegExp(r'\s+'), '');
      for (final photo in photos) {
        try {
          Uint8List bytes;
          if (photo.photoUrl.startsWith('http')) {
            final resp = await http.get(Uri.parse(photo.photoUrl));
            if (resp.statusCode != 200) continue;
            bytes = resp.bodyBytes;
          } else {
            final file = File(photo.photoUrl);
            if (!await file.exists()) continue;
            bytes = await file.readAsBytes();
          }
          final label = photo.label.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
          final ext = p.extension(photo.photoUrl);
          final name = 'photos/$sectionFolder/$label$ext';
          archive.addFile(ArchiveFile(name, bytes.length, bytes));
        } catch (_) {}
      }
    }
  }

  final zipData = ZipEncoder().encode(archive);

  Future<void> logExport(String url) async {
    try {
      await FirebaseFirestore.instance.collection('legalCopies').add({
        'reportId': report.id,
        if (userId != null) 'userId': userId,
        'timestamp': Timestamp.now(),
        'url': url,
      });
    } catch (_) {}
  }

  if (kIsWeb || auto) {
    final storage = FirebaseStorage.instance;
    final ref = storage.ref().child('legal_copies/${report.id}/$fileName');
    await ref.putData(Uint8List.fromList(zipData),
        SettableMetadata(contentType: 'application/zip'));
    final url = await ref.getDownloadURL();
    await logExport(url);
    if (kIsWeb && !auto) {
      html.AnchorElement(href: url)
        ..target = '_blank'
        ..click();
    }
    return null;
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
  await file.writeAsBytes(zipData, flush: true);
  await logExport(file.path);
  return file;
}

Future<String> _generateHtml(SavedReport report) async {
  final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString('report_settings');
  final themeData = prefs.getString('report_theme');
  bool showGps = true;
  if (data != null) {
    final map = jsonDecode(data) as Map<String, dynamic>;
    showGps = map['showGpsData'] as bool? ?? true;
  }
  ReportTheme theme = ReportTheme.defaultTheme;
  if (themeData != null) {
    theme = ReportTheme.fromMap(jsonDecode(themeData) as Map<String, dynamic>);
  }
  final buffer = StringBuffer()
    ..writeln('<html><head><title>Photo Report</title>')
    ..writeln('<style>body{font-family:${theme.fontFamily},sans-serif;} h2{background:#${theme.primaryColor.toRadixString(16).padLeft(8,'0').substring(2)};padding:4px;}</style>')
    ..writeln('</head><body>')
    ..writeln('<img src="${theme.logoPath ?? 'assets/images/clearsky_logo.png'}" width="150"><h1>Roof Inspection Report</h1>')
    ..writeln('<p><strong>Client Name:</strong> ${meta.clientName}<br>')
    ..writeln('<strong>Property Address:</strong> ${meta.propertyAddress}<br>')
    ..writeln(
        '<strong>Inspection Date:</strong> ${meta.inspectionDate.toLocal().toString().split(' ')[0]}</p>');

  buffer.writeln('<p><strong>Insurance Carrier:</strong> ${meta.insuranceCarrier}</p>');
  buffer.writeln('<p><strong>Peril Type:</strong> ${meta.perilType.name}</p>');
  buffer.writeln('<p><strong>Inspection Type:</strong> ${meta.inspectionType.name}</p>');
  final roleText = meta.inspectorRoles.map((e) => e.name.replaceAll('_', ' ')).join(', ');
  buffer.writeln('<p><strong>Inspector Role:</strong> $roleText</p>');
  buffer.writeln('<p><strong>Inspector Name:</strong> ${meta.inspectorName}</p>');
  final aiStatus = report.aiSummary?.status;
  final showSummary =
      aiStatus == 'approved' || aiStatus == 'edited';
  if (showSummary && report.summaryText != null && report.summaryText!.isNotEmpty) {
    buffer
      ..writeln('<div style="border:1px solid #ccc;padding:8px;margin-top:20px;">')
      ..writeln('<strong>Inspection Summary</strong><br>')
      ..writeln('<p>${report.summaryText}</p>');
    if (report.aiSummary?.editor != null) {
      final ts = report.aiSummary!.editedAt?.toLocal().toString().split(' ').first;
      buffer.writeln('<p><em>Reviewed by ${report.aiSummary!.editor} on $ts</em></p>');
    }
    buffer.writeln('</div>');
  }
  if (report.summary != null && report.summary!.isNotEmpty) {
    buffer
      ..writeln('<div style="border:1px solid #ccc;padding:8px;margin-top:20px;">')
      ..writeln('<strong>Inspector Notes / Summary</strong><br>')
      ..writeln('<p>${report.summary}</p>')
      ..writeln('</div>');
  }
  if (report.attachments.isNotEmpty) {
    buffer.writeln('<h2>Attachments</h2><ul>');
    for (final att in report.attachments) {
      final label = att.tag.isNotEmpty ? att.tag : att.name;
      buffer.writeln('<li><a href="${att.url}">$label</a></li>');
    }
    buffer.writeln('</ul>');
  }

  if (report.structures.length > 1) {
    buffer.writeln('<h2>Table of Contents</h2><ul>');
    for (int i = 0; i < report.structures.length; i++) {
      buffer.writeln(
          '<li><a href="#prop${i + 1}">${report.structures[i].name}</a></li>');
    }
    buffer.writeln('</ul>');
  }

    for (int i = 0; i < report.structures.length; i++) {
      final struct = report.structures[i];
      if (report.structures.length > 1) {
        buffer.writeln('<h2 id="prop${i + 1}">${struct.name}</h2>');
        if (struct.address != null && struct.address!.isNotEmpty) {
          buffer.writeln('<p><strong>Address:</strong> ${struct.address}</p>');
        }
      }
      for (final section
          in sectionsForType(meta.inspectionType)) {
        final photos = struct.sectionPhotos[section] ?? [];
      if (photos.isEmpty) continue;
      if (report.structures.length > 1) {
        buffer.writeln('<h3>$section</h3>');
      } else {
        buffer.writeln('<h2>$section</h2>');
      }
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
        '<footer style="background:#eee;padding:10px;margin-top:20px;font-size:12px;text-align:center;">$_disclaimerText</footer>')
    ..writeln('</body></html>');

  return buffer.toString();
}

Future<Uint8List> generatePdf(SavedReport report) => _generatePdf(report);

Future<Uint8List> _generatePdf(SavedReport report) async {
  final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
  final prefs = await SharedPreferences.getInstance();
  final data = prefs.getString('report_settings');
  final themeData = prefs.getString('report_theme');
  bool showGps = true;
  if (data != null) {
    final map = jsonDecode(data) as Map<String, dynamic>;
    showGps = map['showGpsData'] as bool? ?? true;
  }
  ReportTheme theme = ReportTheme.defaultTheme;
  if (themeData != null) {
    theme = ReportTheme.fromMap(jsonDecode(themeData) as Map<String, dynamic>);
  }
  final pdf = pw.Document();

  List<String> collectIssues(List<ReportPhotoEntry> photos,
      {bool missingTestSquare = false}) {
    final issues = <String>{};
    for (final p in photos) {
      if (p.note.isNotEmpty) issues.add(p.note);
      if (p.damageType.isNotEmpty && p.damageType != 'Unknown') {
        issues.add(formatDamageLabel(p.damageType, meta.inspectorRoles));
      }
    }
    if (missingTestSquare) {
      issues.add('No test square photo included for this slope');
    }
    return issues.toList();
  }

  Future<pw.Widget> buildWrap(List<ReportPhotoEntry> photos) async {
    final items = <pw.Widget>[];
      for (final photo in photos) {
        try {
          final file = File(photo.photoUrl);
          if (!await file.exists()) continue;
          final bytes = await file.readAsBytes();
          final label = photo.label.isNotEmpty ? photo.label : 'Unlabeled';
          final damage =
              formatDamageLabel(photo.damageType, meta.inspectorRoles);
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
                pw.Text('Source: ${photo.sourceType.name}${photo.captureDevice != null ? ' (${photo.captureDevice})' : ''}',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        );
      } catch (_) {}
    }
    return pw.Wrap(spacing: 10, runSpacing: 10, children: items);
  }

  Future<List<pw.Widget>> buildSections() async {
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

    final widgets = <pw.Widget>[];
    for (int i = 0; i < report.structures.length; i++) {
      final struct = report.structures[i];
      if (report.structures.length > 1) {
        widgets.add(_pdfSectionHeader('${i + 1}. ${struct.name}'));
        if (struct.address != null && struct.address!.isNotEmpty) {
          widgets.add(pw.Text(struct.address!));
        }
        widgets.add(pw.SizedBox(height: 10));
      }

      final estPhotos = <ReportPhotoEntry>[];
      for (final sec in establishing) {
        estPhotos.addAll(struct.sectionPhotos[sec] ?? []);
      }
      if (estPhotos.isNotEmpty) {
        widgets.add(_pdfSectionHeader('Establishing Shots'));
        final issues = collectIssues(estPhotos);
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
        final missing = struct.slopeTestSquare[section] == false;
        final issues = collectIssues(photos, missingTestSquare: missing);
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
        final missing = struct.slopeTestSquare[entry.key] == false;
        final issues = collectIssues(photos, missingTestSquare: missing);
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

      if (struct.interiorRooms.isNotEmpty) {
        widgets.add(_pdfSectionHeader('Interior Damage'));
        for (final room in struct.interiorRooms) {
          final photos = room.photos;
          if (photos.isEmpty) continue;
          widgets.add(_pdfSectionHeader(room.name));
          if (room.summary.isNotEmpty) {
            widgets.add(pw.Text(room.summary));
            widgets.add(pw.SizedBox(height: 8));
          }
          if (room.checklist.isNotEmpty) {
            widgets.add(pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Checklist:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ...room.checklist.entries
                      .where((e) => e.value)
                      .map((e) => pw.Bullet(text: e.key)),
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

  final widgets = await buildSections();
  final logoData = await rootBundle.load(theme.logoPath ?? 'assets/images/clearsky_logo.png');
  final logoBytes = logoData.buffer.asUint8List();
  final dateStr = DateTime.now().toLocal().toString().split(' ')[0];
  final summary = report.summary ?? '';
  final summaryText = report.summaryText ?? '';
  final aiStatus = report.aiSummary?.status;

  pdf
    ..addPage(
      pw.Page(
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
              if (report.wasOffline)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    '⚠️ Draft Created Offline — Please verify all data before submission',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.orange),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(pw.MemoryImage(logoBytes), width: 150),
              pw.SizedBox(height: 20),
              pw.Text('Roof Inspection Report',
                  style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(theme.primaryColor))),
              pw.SizedBox(height: 10),
              pw.Text(
                  meta.inspectorRoles.contains(InspectorReportRole.adjuster)
                      ? 'Prepared from Adjuster Perspective'
                      : 'Prepared by: Third-Party Inspector',
                  style: pw.TextStyle(
                      fontSize: 18, color: PdfColor.fromInt(theme.primaryColor))),
              pw.SizedBox(height: 20),
              pw.Text('Client Name: ${meta.clientName}'),
              pw.Text('Property Address: ${meta.propertyAddress}'),
              pw.Text(
                  'Inspection Date: ${meta.inspectionDate.toLocal().toString().split(' ')[0]}'),
              pw.Text('Insurance Carrier: ${meta.insuranceCarrier}'),
              pw.Text('Peril Type: ${meta.perilType.name}'),
              pw.Text('Inspection Type: ${meta.inspectionType.name}'),
              pw.Text('Inspector Role: ${meta.inspectorRoles.map((e) => e.name.replaceAll('_', ' ')).join(', ')}'),
              pw.Text('Inspector Name: ${meta.inspectorName}'),
              pw.SizedBox(height: 20),
              if ((aiStatus == 'approved' || aiStatus == 'edited') &&
                  summaryText.isNotEmpty)
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
                      pw.SizedBox(height: 4),
                      pw.Text(summaryText),
                      if (report.aiSummary?.editor != null)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 4),
                          child: pw.Text(
                              'Reviewed by ${report.aiSummary!.editor} on ${report.aiSummary!.editedAt?.toLocal().toString().split(' ')[0]}',
                              style: const pw.TextStyle(fontSize: 10)),
                        ),
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
              if (report.wasOffline)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    '⚠️ Draft Created Offline — Please verify all data before submission',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.orange),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
        build: (context) => [
          pw.Header(level: 0, text: 'ClearSky Photo Report'),
          pw.Text('Client Name: ${meta.clientName}'),
          pw.Text('Property Address: ${meta.propertyAddress}'),
          if (report.structures.length > 1) ...[
            pw.SizedBox(height: 10),
            pw.Header(level: 1, text: 'Table of Contents'),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < report.structures.length; i++)
                  pw.Text('${i + 1}. ${report.structures[i].name}'),
              ],
            ),
            pw.SizedBox(height: 20),
          ],
          pw.Text(
              'Inspection Date: ${meta.inspectionDate.toLocal().toString().split(' ')[0]}'),
          pw.Text('Insurance Carrier: ${meta.insuranceCarrier}'),
          pw.Text('Peril Type: ${meta.perilType.name}'),
          pw.Text('Inspection Type: ${meta.inspectionType.name}'),
          pw.Text('Inspector Role: ${meta.inspectorRoles.map((e) => e.name.replaceAll('_', ' ')).join(', ')}'),
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
              pw.Text('${meta.inspectorName} – $dateStr'),
            ],
          ),
          if (report.homeownerSignature != null && !report.homeownerSignature!.declined) ...[
            pw.SizedBox(height: 20),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(height: 1, width: double.infinity, color: PdfColors.black),
                pw.SizedBox(height: 8),
                pw.Text('Homeowner Signature'),
                pw.SizedBox(height: 4),
                pw.Image(pw.MemoryImage(base64Decode(report.homeownerSignature!.image)), height: 80),
                pw.Text('Signed by ${report.homeownerSignature!.name} – ${report.homeownerSignature!.timestamp.toLocal().toString().split(' ')[0]}'),
              ],
            ),
          ],
          if (report.homeownerSignature != null && report.homeownerSignature!.declined)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 20),
              child: pw.Text('Client declined to sign: ${report.homeownerSignature!.declineReason ?? ''}'),
            ),
        ],
      ),
    );

  return pdf.save();
}

String _csvEscape(String? value) {
  final v = value ?? '';
  if (v.contains(RegExp(r'[",\n]'))) {
    final escaped = v.replaceAll('"', '""');
    return '"$escaped"';
  }
  return v;
}

String _fileNameFromUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return p.basename(uri.path);
  } catch (_) {
    return p.basename(url);
  }
}

/// Generate a CSV string of all photo entries in [report].
String generateCsv(SavedReport report) {
  final buffer = StringBuffer();
  buffer.writeln(
      'file_name,structure,section,label,note,timestamp,latitude,longitude');
  for (final struct in report.structures) {
    for (final entry in struct.sectionPhotos.entries) {
      for (final photo in entry.value) {
        final fileName = _fileNameFromUrl(photo.photoUrl);
        final ts = photo.timestamp?.toIso8601String() ?? '';
        final lat = photo.latitude?.toString() ?? '';
        final lon = photo.longitude?.toString() ?? '';
        buffer.writeln([
          fileName,
          struct.name,
          entry.key,
          photo.label,
          photo.note,
          ts,
          lat,
          lon
        ].map(_csvEscape).join(','));
      }
    }
  }
  return buffer.toString();
}

/// Exports [report] as a CSV file saved to the user's device.
/// Returns the saved file on mobile platforms or null on web.
Future<File?> exportCsv(SavedReport report) async {
  final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
  final addressSlug = _slugify(meta.propertyAddress);
  final fileName = '${addressSlug}_inspection.csv';
  final csvStr = generateCsv(report);
  final bytes = utf8.encode(csvStr);

  if (kIsWeb) {
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
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

  final path = p.join(dir.path, fileName);
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

/// Generates a simple PDF cover sheet with a QR code linking to the
/// public report portal. The PDF includes the ClearSky logo and basic
/// report details.
Future<Uint8List> generateQrCoverSheet({
  required String url,
  required String propertyAddress,
  required String clientName,
  DateTime? inspectionDate,
}) async {
  final pdf = pw.Document();
  final logoData = await rootBundle.load('assets/images/clearsky_logo.png');
  final logoBytes = logoData.buffer.asUint8List();

  pdf.addPage(
    pw.Page(
      build: (context) => pw.Center(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Image(pw.MemoryImage(logoBytes), width: 140),
            pw.SizedBox(height: 20),
            pw.Text('Scan to View Report',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.BarcodeWidget(
              barcode: pw.Barcode.qrCode(),
              data: url,
              width: 200,
              height: 200,
            ),
            pw.SizedBox(height: 20),
            pw.Text(propertyAddress),
            pw.Text(clientName),
            if (inspectionDate != null)
              pw.Text(
                  'Inspection Date: ${inspectionDate.toLocal().toString().split(' ')[0]}'),
            pw.SizedBox(height: 20),
            pw.Text(url, style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
      ),
    ),
  );

  return pdf.save();
}
