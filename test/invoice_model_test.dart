import 'package:flutter_test/flutter_test.dart';
import 'package:clearsky_photo_reports/models/invoice.dart';

void main() {
  test('invoice total from items', () {
    final invoice = Invoice(
      clientName: 'A',
      reportId: '1',
      items: [
        InvoiceLineItem(description: 'x', amount: 5),
        InvoiceLineItem(description: 'y', amount: 7),
      ],
      dueDate: DateTime.now(),
    );
    expect(invoice.amount, 12);
    expect(invoice.createdAt.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
  });
}
