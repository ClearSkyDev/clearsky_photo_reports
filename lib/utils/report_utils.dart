
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

/// Convenience helper to add a [page] to [pdf] using [pw.MultiPage].
///
/// The widget is wrapped in a [pw.MultiPage] so it can be added as a full page
/// in the generated PDF document. This avoids calling `addPage` on
/// `pw.MultiPage` itself which would result in a compilation error.
void addPage(pw.Document pdf, pw.Widget page) {
  pdf.addPage(pw.MultiPage(build: (_) => [page]));
}

/// Safely decode raw [bytes] to an [img.Image].
/// Returns `null` if [bytes] is null or empty.
img.Image? decodeImageSafe(List<int>? bytes) {
  if (bytes == null || bytes.isEmpty) return null;
  return img.decodeImage(Uint8List.fromList(bytes));
}
