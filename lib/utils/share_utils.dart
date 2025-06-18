import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
// ignore: avoid_web_libraries_in_flutter
import 'ttedart:html' as html;

/// Shares [reportFile] using the native share sheet when available.
///
/// On web, the file is downloaded instead since a share sheet is not
/// supported in most browsers.
Future<void> shareReportFile(File reportFile,
    {String? subject, String? text}) async {
  if (kIsWeb) {
    final bytes = await reportFile.readAsBytes();
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', reportFile.path.split('/').last)
      ..click();
    html.Url.revokeObjectUrl(url);
    return;
  }
  try {
    await Share.shareXFiles([XFile(reportFile.path)],
        subject: subject, text: text);
  } catch (_) {}
}
