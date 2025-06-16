import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/invoice.dart';
import '../services/invoice_service.dart';

class InvoiceListScreen extends StatelessWidget {
  final bool unpaidOnly;
  const InvoiceListScreen({super.key, this.unpaidOnly = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: FutureBuilder<List<Invoice>>( 
        future: InvoiceService().fetchInvoices(unpaidOnly: unpaidOnly),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final invoices = snapshot.data!;
          if (invoices.isEmpty) {
            return const Center(child: Text('No invoices'));
          }
          return ListView.builder(
            itemCount: invoices.length,
            itemBuilder: (c, i) {
              final inv = invoices[i];
              return ListTile(
                title: Text(inv.clientName),
                subtitle: Text('Due: ' + inv.dueDate.toLocal().toString().split(' ')[0]),
                trailing: Text(inv.amount.toStringAsFixed(2)),
                onTap: inv.paymentUrl != null
                    ? () => launchUrl(Uri.parse(inv.paymentUrl!))
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}
