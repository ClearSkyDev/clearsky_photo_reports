import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

import 'package:clearsky_photo_reports/src/core/models/local_inspection.dart';

class OfflineSyncService {
  static Future<void> syncAll() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final box = await Hive.openBox<LocalInspection>('inspections');
    for (var inspection in box.values.where((i) => !i.isSynced)) {
      // Upload metadata
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('inspections')
          .doc(inspection.inspectionId)
          .set(inspection.metadata);

      // Upload photos
      for (var photo in inspection.photos) {
        final file = File(photo['localPath']);
        final ref = FirebaseStorage.instance
            .ref('users/$uid/inspections/${inspection.inspectionId}/photos/${photo['filename']}');
        final result = await ref.putFile(file);
        final url = await result.ref.getDownloadURL();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('inspections')
            .doc(inspection.inspectionId)
            .collection('photos')
            .add({
              'url': url,
              'label': photo['label'],
              'timestamp': FieldValue.serverTimestamp(),
            });
      }

      // Mark as synced
      inspection.isSynced = true;
      inspection.save();
    }
  }

  static Future<bool> hasUnsyncedData() async {
    final box = await Hive.openBox<LocalInspection>('inspections');
    return box.values.any((i) => !i.isSynced);
  }
}
