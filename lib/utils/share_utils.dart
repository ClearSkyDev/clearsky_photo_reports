import 'dart:io';
import 'package:share_plus/share_plus.dart';

/// Shares [reportFile] using the native share sheet when available.
Future<void> shareReportFile(File reportFile,
    {String? subject, String? text}) async {
  try {
    await Share.shareXFiles([XFile(reportFile.path)],
        subject: subject, text: text);
  } catch (_) {}
}

Future<void> shareFiles(List<String> filePaths, {String? text}) async {
  final files = filePaths.map((path) => XFile(path)).toList();
  await Share.shareXFiles(files, text: text);
}
