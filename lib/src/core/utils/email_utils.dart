import 'package:flutter/foundation.dart';
// for web interop
import '../../web/js_utils.dart' as web_js;

// Mobile imports
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/report_attachment.dart';

/// Sends the generated report to [email]. On mobile platforms the PDF is
/// attached using `flutter_email_sender`. On web a blob download is triggered
/// and a `mailto:` link is opened. If sending fails on mobile, the share sheet
/// is shown as a fallback.
Future<void> sendReportByEmail(
  String email,
  Uint8List pdfBytes, {
  String subject = 'Roof Inspection Report',
  String message = '',
  List<String> attachmentPaths = const [],
}) async {
  if (kIsWeb) {
    web_js.downloadBytes(pdfBytes, 'report.pdf', 'application/pdf');
    final mailto =
        'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(message)}';
    web_js.openLink(mailto);
    return;
  }

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/report.pdf');
  await file.writeAsBytes(pdfBytes, flush: true);

  final mail = Email(
    body: message,
    subject: subject,
    recipients: [email],
    attachmentPaths: [file.path, ...attachmentPaths],
    isHTML: false,
  );
  try {
    await FlutterEmailSender.send(mail);
  } catch (_) {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: subject,
        text: message,
      ),
    );
  }
}

Future<String> _uploadPdf(Uint8List pdfBytes) async {
  final storage = FirebaseStorage.instance;
  final ref = storage
      .ref()
      .child('email_reports/${DateTime.now().millisecondsSinceEpoch}.pdf');
  await ref.putData(pdfBytes, SettableMetadata(contentType: 'application/pdf'));
  return ref.getDownloadURL();
}

Future<String> uploadAudioFile(File audioFile) async {
  final bytes = await audioFile.readAsBytes();
  final storage = FirebaseStorage.instance;
  final ref = storage
      .ref()
      .child('audio_summaries/${DateTime.now().millisecondsSinceEpoch}.mp3');
  await ref.putData(bytes, SettableMetadata(contentType: 'audio/mpeg'));
  return ref.getDownloadURL();
}

/// Sends the report via email with either an attachment or a cloud link.
Future<void> sendReportEmail(
  String email,
  Uint8List pdfBytes, {
  String subject = 'Roof Inspection Report',
  String message = '',
  String signature = '',
  bool attachPdf = true,
  List<ReportAttachment> attachments = const [],
}) async {
  final fullMessage =
      [message, if (signature.isNotEmpty) signature].join('\n\n');
  if (attachPdf) {
    final localPaths = attachments
        .where((a) => !a.url.startsWith('http'))
        .map((a) => a.url)
        .toList();
    await sendReportByEmail(email, pdfBytes,
        subject: subject, message: fullMessage, attachmentPaths: localPaths);
    return;
  }
  final url = await _uploadPdf(pdfBytes);
  final links = <String>[];
  for (final a in attachments) {
    if (a.url.startsWith('http')) {
      final label = a.tag.isNotEmpty ? a.tag : a.name;
      links.add('$label: ${a.url}');
    }
  }
  final body = [
    message,
    'Download: $url',
    if (links.isNotEmpty) links.join('\n'),
    if (signature.isNotEmpty) signature
  ].join('\n\n');
  if (kIsWeb) {
    final mailto =
        'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}';
    web_js.openLink(mailto);
    return;
  }
  final mail = Email(
    body: body,
    subject: subject,
    recipients: [email],
    isHTML: false,
  );
  try {
    await FlutterEmailSender.send(mail);
  } catch (_) {
    await SharePlus.instance.share(
      ShareParams(text: body, subject: subject),
    );
  }
}
