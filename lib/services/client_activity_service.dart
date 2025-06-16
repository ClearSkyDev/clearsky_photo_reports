import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientActivityService {
  final _collection = FirebaseFirestore.instance.collection('clientActivity');

  Future<void> log(String event, {String? reportId}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _collection.add({
      'uid': user.uid,
      if (reportId != null) 'reportId': reportId,
      'event': event,
      'timestamp': Timestamp.now(),
    });
  }
}
