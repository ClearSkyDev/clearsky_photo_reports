/// Utilities for sending reports via email (web implementation).
///
/// Currently only supports opening the client's email application with
/// a prepared draft. The PDF bytes are converted to a Blob so the user
/// can download or attach the file manually.
///
/// TODO: Explore Firebase functions to send emails directly from the backend.

import 'dart:html' as html;
import 'dart:typed_data';

/// Opens the default mail client with a draft addressed to [email].
///
/// A Blob is generated from [pdfBytes] so the browser prompts the user
/// to download the PDF, which can then be manually attached to the email.
void sendReportByEmail(String email, Uint8List pdfBytes) {
  // Create a blob URL for the PDF data so the user can download it.
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  // Trigger a download for the PDF file.
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'report.pdf')
    ..click();

  html.Url.revokeObjectUrl(url);

  // Open the user's mail client. Attachments cannot be added via mailto,
  // so the user will need to attach the downloaded PDF manually.
  final mailto = 'mailto:$email?subject=Roof%20Inspection%20Report';
  html.AnchorElement(href: mailto)..click();
}
