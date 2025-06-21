
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

/// Convenience wrapper around [pw.Document.addPage].
///
/// This ensures the [pw.MultiPage] widget is added to the provided [pdf]
/// document correctly.
void addPage(pw.Document pdf, pw.MultiPage page) {
  pdf.addPage(page);
}

/// Safely decode raw [bytes] to an [img.Image].
/// Returns `null` if [bytes] is null or empty.
img.Image? decodeImageSafe(List<int>? bytes) {
  if (bytes == null || bytes.isEmpty) return null;
  return img.decodeImage(bytes);
}
