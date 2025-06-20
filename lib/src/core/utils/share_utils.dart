import 'dart:io';
import 'package:share_plus/share_plus.dart';

/// Shares [reportFile] using the native share sheet when available.
Future<void> shareReportFile(File reportFile,
    {String? subject, String? text}) async {
  try {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(reportFile.path)],
        subject: subject,
        text: text,
      ),
    );
  } catch (_) {}
}

Future<void> shareFiles(List<String> filePaths, {String? text}) async {
  final files = filePaths.map((path) => XFile(path)).toList();
  await SharePlus.instance.share(
    ShareParams(files: files, text: text),
  );
}
