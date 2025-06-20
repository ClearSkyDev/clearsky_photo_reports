import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/partner.dart';

class PartnerService {
  final _partners = FirebaseFirestore.instance.collection('partners');

  Future<Partner?> getByCode(String? code) async {
    if (code == null || code.isEmpty) return null;
    final snap = await _partners.where('code', isEqualTo: code).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return Partner.fromMap(doc.id, doc.data());
  }

  Stream<List<Partner>> streamPartners() {
    return _partners.snapshots().map(
        (s) => s.docs.map((d) => Partner.fromMap(d.id, d.data())).toList());
  }
}
