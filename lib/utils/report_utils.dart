import 'package:pdf/widgets.dart' as pw;

/// Convenience wrapper around [pw.Document.addPage].
void addPage(pw.Document doc, pw.Page page) {
  doc.addPage(page);
}
