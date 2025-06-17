import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// Web imports
import 'dart:html' as html show Blob, Url, AnchorElement;

// Mobile imports
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

/// Sends the generated report to [email]. On mobile platforms the PDF is
/// attached using `flutter_email_sender`. On web a blob download is triggered
/// and a `mailto:` link is opened. If sending fails on mobile, the share sheet
/// is shown as a fallback.
Future<void> sendReportByEmail(
  String email,
  Uint8List pdfBytes, {
  String subject = 'Roof Inspection Report',
  String message = '',
}) async {
  if (kIsWeb) {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'report.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
    final mailto =
        'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(message)}';
    html.AnchorElement(href: mailto)..click();
    return;
  }

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/report.pdf');
  await file.writeAsBytes(pdfBytes, flush: true);

  final mail = Email(
    body: message,
    subject: subject,
    recipients: [email],
    attachmentPaths: [file.path],
    isHTML: false,
  );
  try {
    await FlutterEmailSender.send(mail);
  } catch (_) {
    await Share.shareXFiles([XFile(file.path)], subject: subject, text: message);
  }
}
