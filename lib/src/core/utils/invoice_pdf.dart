import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/invoice.dart';

Future<Uint8List> generateInvoicePdf(Invoice invoice) async {
  final doc = pw.Document();

  doc.addPage(
    pw.Page(
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('ClearSky Roof Inspectors',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Invoice for ${invoice.clientName}',
                style: pw.TextStyle(fontSize: 18)),
            pw.Text(
                'Due: ${invoice.dueDate.toLocal().toString().split(' ')[0]}'),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Item')),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Amount')),
                  ],
                ),
                ...invoice.items.map(
                  (e) => pw.TableRow(children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(e.description)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('\$${e.amount.toStringAsFixed(2)}')),
                  ]),
                ),
                pw.TableRow(children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Total',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('\$${invoice.amount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold))),
                ]),
              ],
            ),
            if (invoice.paymentUrl != null) ...[
              pw.SizedBox(height: 16),
              pw.UrlLink(
                destination: invoice.paymentUrl!,
                child: pw.Text('Pay Online',
                    style: pw.TextStyle(color: PdfColors.blue)),
              )
            ],
          ],
        );
      },
    ),
  );

  return doc.save();
}
