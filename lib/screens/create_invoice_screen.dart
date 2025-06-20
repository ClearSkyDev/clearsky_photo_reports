import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/invoice.dart';
import '../services/invoice_service.dart';
import '../utils/invoice_pdf.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final String reportId;
  final String clientName;
  const CreateInvoiceScreen(
      {super.key, required this.reportId, required this.clientName});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final List<InvoiceLineItem> _items = [];
  DateTime? _dueDate;
  final TextEditingController _paymentController = TextEditingController();

  double get _total {
    double t = 0;
    for (final item in _items) {
      t += item.amount;
    }
    return t;
  }

  Future<void> _save() async {
    final invoice = Invoice(
      clientName: widget.clientName,
      reportId: widget.reportId,
      items: _items,
      dueDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
      paymentUrl:
          _paymentController.text.isEmpty ? null : _paymentController.text,
    );
    await InvoiceService().createInvoice(invoice);
    final pdf = await generateInvoicePdf(invoice);
    await Printing.sharePdf(bytes: pdf, filename: 'invoice.pdf');
    if (mounted) Navigator.pop(context);
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceLineItem(description: '', amount: 0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Invoice')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _paymentController,
              decoration: const InputDecoration(labelText: 'Payment URL'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (c, i) {
                  final item = _items[i];
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => item.description = v,
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (v) =>
                              item.amount = double.tryParse(v) ?? 0,
                          decoration:
                              const InputDecoration(labelText: 'Amount'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Remove Item',
                        onPressed: () => setState(() => _items.removeAt(i)),
                      )
                    ],
                  );
                },
              ),
            ),
            TextButton(onPressed: _addItem, child: const Text('Add Line Item')),
            Text('Total: ${_total.toStringAsFixed(2)}'),
            ElevatedButton(onPressed: _save, child: const Text('Save Invoice')),
          ],
        ),
      ),
    );
  }
}
