import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/invoice.dart';

class InvoiceService {
  final _collection = FirebaseFirestore.instance.collection('invoices');

  Future<String> createInvoice(Invoice invoice) async {
    final doc = _collection.doc();
    await doc.set({
      ...invoice.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await FirebaseFirestore.instance
        .collection('metrics')
        .doc(invoice.reportId)
        .set({'invoiceAmount': invoice.amount}, SetOptions(merge: true));
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

  Future<Invoice?> fetchInvoiceForReport(String reportId) async {
    final snap = await _collection
        .where('reportId', isEqualTo: reportId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return Invoice.fromMap(doc.data(), doc.id);
  }
}
