import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Invoice {
  final String id;
  final String clientName;
  final String jobLocation;
  final double totalAmount;
  final DateTime date;

  Invoice({
    required this.id,
    required this.clientName,
    required this.jobLocation,
    required this.totalAmount,
    required this.date,
  });
}

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  InvoiceListScreenState createState() => InvoiceListScreenState();
}

class InvoiceListScreenState extends State<InvoiceListScreen> {
  final List<Invoice> _invoices = [];

  void _addDummyInvoice() {
    final now = DateTime.now();
    setState(() {
      _invoices.add(
        Invoice(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          clientName: 'John Doe',
          jobLocation: '123 Main St',
          totalAmount: 250.00,
          date: now,
        ),
      );
    });
  }

  void _deleteInvoice(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text('Are you sure you want to delete this invoice?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              setState(() {
                _invoices.removeAt(index);
              });
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }


  void _openInvoice(Invoice invoice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(invoice.clientName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${invoice.jobLocation}'),
            Text('Total: \$${invoice.totalAmount.toStringAsFixed(2)}'),
            Text('Date: ${DateFormat.yMMMd().format(invoice.date)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Invoices'),
      ),
      body: _invoices.isEmpty
          ? const Center(child: Text('No invoices yet.'))
          : ListView.builder(
              itemCount: _invoices.length,
              itemBuilder: (context, index) {
                final invoice = _invoices[index];
                return ListTile(
                  title: Text(invoice.clientName),
                  subtitle: Text(
                      '${invoice.jobLocation} • \$${invoice.totalAmount.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteInvoice(index),
                  ),
                  onTap: () => _openInvoice(invoice),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // In the future: Collect real data, then add to _invoices
          _addDummyInvoice();
          // Or:
          // final result = await Navigator.push(...CreateInvoiceScreen());
          // if (result is Invoice) setState(() => _invoices.add(result));
        },
        tooltip: 'New Invoice',
        child: const Icon(Icons.add),
      ),
    );
  }
}
