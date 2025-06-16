import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/invoice.dart';

class InvoiceService {
  final _collection = FirebaseFirestore.instance.collection('invoices');

  Future<String> createInvoice(Invoice invoice) async {
    final doc = _collection.doc();
    await doc.set(invoice.toMap());
    return doc.id;
  }

  Future<List<Invoice>> fetchInvoices({bool unpaidOnly = false}) async {
    Query<Map<String, dynamic>> q = _collection;
    if (unpaidOnly) {
      q = q.where('isPaid', isEqualTo: false);
    }
    final snap = await q.get();
    return snap.docs
        .map((d) => Invoice.fromMap(d.data(), d.id))
        .toList();
  }

  Future<void> markPaid(String id) {
    return _collection.doc(id).update({'isPaid': true});
  }
}
