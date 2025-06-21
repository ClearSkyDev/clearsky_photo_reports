import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/saved_report.dart';
import '../models/inspected_structure.dart';
import '../models/report_attachment.dart';
import 'offline_draft_store.dart';
import '../utils/sync_preferences.dart';
import 'sync_history_service.dart';
import '../models/sync_log_entry.dart';
import '../models/pending_photo.dart';
import 'pending_photo_store.dart';

class OfflineSyncService {
  OfflineSyncService._();
  static final OfflineSyncService instance = OfflineSyncService._();

  final ValueNotifier<bool> online = ValueNotifier(true);
  final ValueNotifier<double> progress = ValueNotifier(0);
  StreamSubscription<ConnectivityResult>? _connSub;
  Timer? _timer;

  Future<void> init() async {
    debugPrint('[OfflineSyncService] init');
    await Hive.initFlutter();
    await OfflineDraftStore.instance.init();
    await PendingPhotoStore.instance.init();
    await SyncHistoryService.instance.init();
    final initial = await Connectivity().checkConnectivity();
    final initResult =
        initial.isNotEmpty ? initial.first : ConnectivityResult.none;
    online.value = initResult != ConnectivityResult.none;
    // Perform an initial sync on startup
    if (online.value) {
      unawaited(syncDrafts());
    }
    // Periodically attempt to sync any drafts
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => syncDrafts());
    _connSub = Connectivity()
        .onConnectivityChanged
        .map((results) =>
            results.isNotEmpty ? results.first : ConnectivityResult.none)
        .listen((ConnectivityResult result) {
      final newOnline = result != ConnectivityResult.none;
      if (!online.value && newOnline) {
        syncDrafts();
      }
      online.value = newOnline;
    });
  }

  Future<void> dispose() async {
    debugPrint('[OfflineSyncService] dispose');
    await _connSub?.cancel();
    _timer?.cancel();
  }

  Future<void> saveDraft(SavedReport report) {
    debugPrint('[OfflineSyncService] saveDraft ${report.id}');
    return OfflineDraftStore.instance.saveReport(report);
  }

  int get pendingCount => OfflineDraftStore.instance.count;

  Future<void> syncDrafts() async {
    debugPrint('[OfflineSyncService] syncDrafts start');
    if (!online.value) return;
    if (!await SyncPreferences.isCloudSyncEnabled()) return;
    final drafts = OfflineDraftStore.instance.loadReports();
    if (drafts.isEmpty) return;
    progress.value = 0;
    for (var i = 0; i < drafts.length; i++) {
      final draft = drafts[i];
      try {
        await _uploadDraft(draft);
        await OfflineDraftStore.instance.delete(draft.id);
        await SyncHistoryService.instance.addEntry(SyncLogEntry(
          reportId: draft.id,
          success: true,
          message: 'Synced successfully',
        ));
      } catch (e) {
        await SyncHistoryService.instance.addEntry(SyncLogEntry(
          reportId: draft.id,
          success: false,
          message: e.toString(),
        ));
      }
      progress.value = (i + 1) / drafts.length;
    }
    debugPrint('[OfflineSyncService] syncDrafts complete');
  }

  Future<void> syncPendingPhotos(String inspectionId) async {
    debugPrint('[OfflineSyncService] syncPendingPhotos $inspectionId');
    if (!online.value) return;
    if (!await SyncPreferences.isCloudSyncEnabled()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final photos = PendingPhotoStore.instance.loadUnsynced(inspectionId);
    if (photos.isEmpty) return;

    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    for (final pending in photos) {
      final file = File(pending.path);
      if (!await file.exists()) {
        await PendingPhotoStore.instance.delete(pending.id);
        continue;
      }
      try {
        final ref = storage
            .ref()
            .child('users/$uid/inspections/$inspectionId/photos/${pending.name}');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        await firestore
            .collection('users')
            .doc(uid)
            .collection('inspections')
            .doc(inspectionId)
            .update({'photos': FieldValue.arrayUnion([url])});
        await PendingPhotoStore.instance.delete(pending.id);
      } catch (_) {}
    }
  }

  Future<void> _uploadDraft(SavedReport draft) async {
    debugPrint('[OfflineSyncService] uploading draft ${draft.id}');
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    final existing = await firestore.collection('reports').doc(draft.id).get();
    if (existing.exists) {
      final data = existing.data();
      if (data != null &&
          data['lastEditedAt'] != null &&
          draft.lastEditedAt != null) {
        final remote =
            DateTime.fromMillisecondsSinceEpoch(data['lastEditedAt']);
        if (remote.isAfter(draft.lastEditedAt!)) {
          throw Exception('Conflict detected: remote version newer');
        }
      }
    }

    final structs = <InspectedStructure>[];
    for (final struct in draft.structures) {
      final sections = <String, List<ReportPhotoEntry>>{};
      for (var entry in struct.sectionPhotos.entries) {
        final tasks = <Future<ReportPhotoEntry>>[];
        for (var i = 0; i < entry.value.length; i++) {
          final p = entry.value[i];
          final file = File(p.photoUrl);
          if (!await file.exists()) continue;
          final ref = storage.ref().child(
              'reports/${draft.id}/${struct.name}/${entry.key}/photo_$i.jpg');
          tasks.add(ref.putFile(file).then((_) async {
            final url = await ref.getDownloadURL();
            return ReportPhotoEntry(
              label: p.label,
              caption: p.caption,
              confidence: p.confidence,
              photoUrl: url,
              timestamp: p.timestamp,
              latitude: p.latitude,
              longitude: p.longitude,
              damageType: p.damageType,
              note: p.note,
              sourceType: p.sourceType,
              captureDevice: p.captureDevice,
            );
          }));
        }
        final uploaded = await Future.wait(tasks);
        if (uploaded.isNotEmpty) {
          sections[entry.key] = uploaded;
        }
      }
      structs.add(InspectedStructure(
        name: struct.name,
        sectionPhotos: sections,
        slopeTestSquare: Map.from(struct.slopeTestSquare),
      ));
    }

    String? signatureUrl;
    if (draft.signature != null) {
      try {
        final bytes = draft.signature!.startsWith('data:image')
            ? base64Decode(draft.signature!.split(',').last)
            : await File(draft.signature!).readAsBytes();
        final ref = storage.ref().child('reports/${draft.id}/signature.png');
        await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
        signatureUrl = await ref.getDownloadURL();
      } catch (_) {}
    }

    final uploadedAttachments = <ReportAttachment>[];
    for (final att in draft.attachments) {
      if (att.isExternalUrl || att.url.startsWith('http')) {
        uploadedAttachments.add(att);
        continue;
      }
      final file = File(att.url);
      if (!await file.exists()) continue;
      final name = p.basename(att.url);
      final ref = storage.ref().child('reports/${draft.id}/attachments/$name');
      try {
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        uploadedAttachments.add(ReportAttachment(
          name: att.name,
          url: url,
          tag: att.tag,
          type: att.type,
          uploadedAt: att.uploadedAt,
        ));
      } catch (_) {}
    }

    final saved = SavedReport(
      id: draft.id,
      version: draft.version,
      userId: draft.userId,
      inspectionMetadata: draft.inspectionMetadata,
      structures: structs,
      summary: draft.summary,
      summaryText: draft.summaryText,
      aiSummary: draft.aiSummary,
      signature: signatureUrl,
      templateId: draft.templateId,
      createdAt: draft.createdAt,
      isFinalized: draft.isFinalized,
      signatureRequested: draft.signatureRequested,
      signatureStatus: draft.signatureStatus,
      publicReportId: draft.publicReportId,
      publicViewLink: draft.publicViewLink,
      theme: draft.theme,
      lastAuditPassed: draft.lastAuditPassed,
      lastAuditIssues: draft.lastAuditIssues,
      reportOwner: draft.reportOwner,
      collaborators: draft.collaborators,
      lastEditedBy: draft.lastEditedBy,
      lastEditedAt: draft.lastEditedAt,
      latitude: draft.latitude,
      longitude: draft.longitude,
      searchIndex: draft.searchIndex,
      attachments: uploadedAttachments,
      wasOffline: draft.wasOffline,
    );

    await firestore.collection('reports').doc(draft.id).set(saved.toMap());
  }
}
