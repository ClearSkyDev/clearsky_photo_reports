
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;

/// Convenience wrapper around [pw.Document.addPage].
void addPage(pw.Document doc, pw.Page page) {
  doc.addPage(page);
}

/// Safely decode raw [bytes] to an [img.Image].
/// Returns `null` if [bytes] is null or empty.
img.Image? decodeImageSafe(List<int>? bytes) {
  if (bytes == null || bytes.isEmpty) return null;
  return img.decodeImage(bytes);
}
