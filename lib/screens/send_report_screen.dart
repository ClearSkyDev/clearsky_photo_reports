import 'package:flutter/material.dart';
import '../models/inspection_metadata.dart';
import '../models/photo_entry.dart';
import '../models/saved_report.dart';
import '../models/inspected_structure.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import '../utils/signature_storage.dart';
import 'capture_signature_screen.dart';
import '../utils/local_report_store.dart';
import '../utils/export_utils.dart';
import '../utils/profile_storage.dart';
import '../models/report_template.dart';
import '../models/checklist.dart';
import '../utils/summary_utils.dart';
import '../services/ai_summary_service.dart';
import '../models/report_collaborator.dart';
import '../models/inspector_profile.dart';
import '../models/partner.dart';
import '../services/partner_service.dart';
import 'package:flutter/services.dart';
import '../services/tts_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/share_utils.dart';
import '../utils/email_utils.dart';
import 'inspection_checklist_screen.dart';
import 'photo_map_screen.dart';
import 'change_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/report_theme.dart';
import 'report_settings_screen.dart' show ReportSettings;
import '../utils/ai_quality_check.dart';
import 'manage_collaborators_screen.dart';
import '../utils/permission_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/offline_sync_service.dart';
import '../utils/sync_preferences.dart';
import '../services/auth_service.dart';
import '../services/audit_log_service.dart';
import '../models/report_attachment.dart';
import 'package:file_picker/file_picker.dart';

/// If Firebase is not desired:
/// - Use `path_provider` and `shared_preferences` or `hive` to save report JSON locally
/// - Save photo paths using app directory
/// - Create a LocalReportStore that mirrors the Firestore logic with local files

class SendReportScreen extends StatefulWidget {
  final InspectionMetadata metadata;
  final List<InspectedStructure>? structures;
  final String? summary;
  final String? summaryText;
  final Uint8List? signature;
  final ReportTemplate? template;

  const SendReportScreen({
    super.key,
    required this.metadata,
    this.structures,
    this.summary,
    this.summaryText,
    this.signature,
    this.template,
  });

  @override
  State<SendReportScreen> createState() => _SendReportScreenState();
}

class _SendReportScreenState extends State<SendReportScreen> {
  final TextEditingController _emailController = TextEditingController();
  late final TextEditingController _summaryTextController;
  bool _saving = false;
  String? _docId;
  SavedReport? _savedReport;
  InspectorProfile? _profile;
  bool _exporting = false;
  Uint8List? _signature;
  bool _signatureLocked = false;
  File? _exportedFile;
  File? _audioFile;
  String? _audioUrl;
  bool _finalized = false;
  bool _requestSignature = false;
  String? _publicId;
  bool _publicLinkEnabled = true;
  final TextEditingController _passwordController = TextEditingController();
  DateTime? _expiryDate;
  bool? _auditPassed;
  List<PhotoAuditIssue> _auditIssues = [];
  Partner? _partner;
  final List<ReportAttachment> _attachments = [];

  Future<void> _maybeRunQualityCheck() async {
    if (_auditPassed == null) {
      await _runQualityCheck();
    }
  }
  String? _jobCost;

  List<PhotoEntry> _gpsPhotos() {
    final result = <PhotoEntry>[];
    if (widget.structures != null) {
      for (final struct in widget.structures!) {
        for (var photos in struct.sectionPhotos.values) {
          for (var p in photos) {
            if (p.latitude != null && p.longitude != null) {
              result.add(p);
            }
          }
        }
      }
    }
    return result;
  }

  int _totalPhotoCount() {
    int count = 0;
    if (widget.structures != null) {
      for (final struct in widget.structures!) {
        for (var photos in struct.sectionPhotos.values) {
          count += photos.length;
        }
      }
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
    _summaryTextController =
        TextEditingController(text: widget.summaryText ?? '');
    _initialize();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _summaryTextController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    _signature = widget.signature ?? await SignatureStorage.load();
    _profile = await ProfileStorage.load();
    _partner = await PartnerService().getByCode(widget.metadata.partnerCode);
    await _saveReport();
  }

  Future<void> _saveReport() async {
    if (_saving) return;
    final cloudEnabled = await SyncPreferences.isCloudSyncEnabled();
    if (!OfflineSyncService.instance.online.value || !cloudEnabled) {
      await _saveReportOffline();
      return;
    }
    setState(() => _saving = true);

    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    final doc = firestore.collection('reports').doc();
    final reportId = doc.id;
    final profile = _profile ?? await ProfileStorage.load();

    Future<List<ReportPhotoEntry>> uploadSection(
        String section, List<PhotoEntry> photos) async {
      final result = <ReportPhotoEntry>[];
      for (var i = 0; i < photos.length; i++) {
        final p = photos[i];
        try {
          final file = File(p.url);
          final ref = storage
              .ref()
              .child('reports/$reportId/$section/photo_$i.jpg');
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          result.add(ReportPhotoEntry(
              label: p.label,
              caption: p.caption,
              confidence: p.labelConfidence,
              photoUrl: url,
              timestamp: p.capturedAt,
              latitude: p.latitude,
              longitude: p.longitude,
              damageType: p.damageType,
              note: p.note,
              sourceType: p.sourceType,
              captureDevice: p.captureDevice));
        } catch (_) {}
      }
      return result;
    }

    final structs = <InspectedStructure>[];

    if (widget.structures != null) {
      for (final struct in widget.structures!) {
        final uploadedSections = <String, List<ReportPhotoEntry>>{};
        for (var entry in struct.sectionPhotos.entries) {
          final uploaded = await uploadSection('${struct.name}/${entry.key}', entry.value);
          if (uploaded.isNotEmpty) {
            uploadedSections[entry.key] = uploaded;
          }
        }
        structs.add(InspectedStructure(name: struct.name, sectionPhotos: uploadedSections));
      }
    }

    String? signatureUrl;
    if (_signature != null) {
      try {
        final ref =
            storage.ref().child('reports/$reportId/signature.png');
        await ref.putData(_signature!,
            SettableMetadata(contentType: 'image/png'));
        signatureUrl = await ref.getDownloadURL();
      } catch (_) {}
    }

    final metadataMap = {
      'clientName': widget.metadata.clientName,
      'propertyAddress': widget.metadata.propertyAddress,
      'inspectionDate':
          widget.metadata.inspectionDate.toIso8601String(),
      'insuranceCarrier': widget.metadata.insuranceCarrier,
      'perilType': widget.metadata.perilType.name,
      'inspectionType': widget.metadata.inspectionType.name,
      'inspectorRole': widget.metadata.inspectorRole.name,
      if (profile?.name != null)
        'inspectorName': profile!.name
      else 'inspectorName': widget.metadata.inspectorName,
      if (widget.metadata.reportId != null)
        'reportId': widget.metadata.reportId,
      if (widget.metadata.weatherNotes != null)
        'weatherNotes': widget.metadata.weatherNotes,
      if (widget.metadata.lastSentTo != null)
        'lastSentTo': widget.metadata.lastSentTo,
      if (widget.metadata.lastSentAt != null)
        'lastSentAt': widget.metadata.lastSentAt!.toIso8601String(),
      if (widget.metadata.lastSendMethod != null)
        'lastSendMethod': widget.metadata.lastSendMethod,
      if (widget.metadata.partnerCode != null)
        'partnerCode': widget.metadata.partnerCode,
      if (widget.metadata.startTimestamp != null)
        'startTimestamp': widget.metadata.startTimestamp!.toIso8601String(),
      if (widget.metadata.startLatitude != null)
        'startLatitude': widget.metadata.startLatitude,
      if (widget.metadata.startLongitude != null)
        'startLongitude': widget.metadata.startLongitude,
      'endTimestamp': DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    ReportTheme theme = ReportTheme.defaultTheme;
    final themeData = prefs.getString('report_theme');
    if (themeData != null) {
      theme = ReportTheme.fromMap(jsonDecode(themeData) as Map<String, dynamic>);
    }

    double? latitude;
    double? longitude;
    final gps = _gpsPhotos();
    if (gps.isNotEmpty) {
      latitude = gps.first.latitude;
      longitude = gps.first.longitude;
    } else {
      try {
        final pos = await Geolocator.getCurrentPosition();
        latitude = pos.latitude;
        longitude = pos.longitude;
      } catch (_) {
        try {
          final locs =
              await locationFromAddress(widget.metadata.propertyAddress);
          if (locs.isNotEmpty) {
            latitude = locs.first.latitude;
            longitude = locs.first.longitude;
          }
        } catch (_) {}
      }
    }

    final labels = <String>{};
    final damages = <String>{};
    for (final struct in structs) {
      for (final photos in struct.sectionPhotos.values) {
        for (final p in photos) {
          if (p.label.isNotEmpty) labels.add(p.label);
          if (p.damageType.isNotEmpty) damages.add(p.damageType);
        }
      }
    }

    final uploadedAttachments = <ReportAttachment>[];
    for (final att in _attachments) {
      if (att.isExternalUrl || att.url.startsWith('http')) {
        uploadedAttachments.add(att);
        continue;
      }
      final file = File(att.url);
      if (!await file.exists()) continue;
      final name = p.basename(att.url);
      try {
        final ref = storage
            .ref()
            .child('reports/$reportId/attachments/$name');
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

    final version = (_savedReport?.version ?? 0) + 1;
    final saved = SavedReport(
      id: reportId,
      version: version,
      userId: profile?.id,
      inspectionMetadata: metadataMap,
      structures: structs,
      summary: widget.summary,
      summaryText: _summaryTextController.text,
      signature: signatureUrl,
      theme: theme,
      templateId: widget.template?.id,
      clientEmail: _emailController.text.isNotEmpty ? _emailController.text : null,
      partnerId: _partner?.id,
      referralDate: _partner != null ? DateTime.now() : null,
      signatureRequested: false,
      signatureStatus: 'none',
      lastAuditPassed: null,
      lastAuditIssues: null,
      reportOwner: profile?.id,
      collaborators: profile != null
          ? [
              ReportCollaborator(
                  id: profile.id,
                  name: profile.name,
                  role: CollaboratorRole.lead)
            ]
          : const [],
      lastEditedBy: profile?.id,
      lastEditedAt: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      jobCost: _jobCost,
      attachments: uploadedAttachments,
      searchIndex: {
        'address': widget.metadata.propertyAddress,
        'address_lc': widget.metadata.propertyAddress.toLowerCase(),
        'clientName': widget.metadata.clientName,
        'clientName_lc': widget.metadata.clientName.toLowerCase(),
        if (profile?.name != null)
          'inspectorName': profile!.name
        else 'inspectorName': widget.metadata.inspectorName,
        if (profile?.name != null)
          'inspectorName_lc': profile!.name.toLowerCase()
        else 'inspectorName_lc': widget.metadata.inspectorName.toLowerCase(),
        'type': widget.metadata.inspectionType.name,
        'type_lc': widget.metadata.inspectionType.name.toLowerCase(),
        'labels': labels.toList(),
        'labels_lc': labels.map((e) => e.toLowerCase()).toList(),
        'damageTags': damages.toList(),
        'damageTags_lc': damages.map((e) => e.toLowerCase()).toList(),
      },
    );

    await doc.set(saved.toMap());

    final metricsRef =
        FirebaseFirestore.instance.collection('metrics').doc(reportId);
    final zipMatch =
        RegExp(r'(\d{5})(?:[-\s]|\b)').firstMatch(widget.metadata.propertyAddress);
    double damagePercent = 0;
    final totalPhotos = _totalPhotoCount();
    if (totalPhotos > 0) {
      int damaged = 0;
      for (final struct in structs) {
        for (final photos in struct.sectionPhotos.values) {
          for (final p in photos) {
            final t = p.damageType.toLowerCase();
            if (t.isNotEmpty && t != 'none' && t != 'unknown') {
              damaged++;
            }
          }
        }
      }
      damagePercent = damaged / totalPhotos * 100;
    }
    await metricsRef.set({
      'inspectorId': profile?.id ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'photoCount': totalPhotos,
      'status': 'draft',
      if (zipMatch != null) 'zipCode': zipMatch.group(1),
      'clientName': widget.metadata.clientName,
      'perilType': widget.metadata.perilType.name,
      'damagePercent': damagePercent,
      if (_partner != null) 'partnerId': _partner!.id,
    });

    setState(() {
      _saving = false;
      _docId = reportId;
      _savedReport = saved;
      _finalized = saved.isFinalized;
      _publicId = saved.publicReportId;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report saved to cloud')),
      );
    }
  }

  Future<void> _saveReportOffline() async {
    if (_saving) return;
    setState(() => _saving = true);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final profile = _profile ?? await ProfileStorage.load();
    final structs = <InspectedStructure>[];
    if (widget.structures != null) {
      for (final struct in widget.structures!) {
        final sections = <String, List<ReportPhotoEntry>>{};
        for (var entry in struct.sectionPhotos.entries) {
          final list = entry.value
              .map((p) => ReportPhotoEntry(
                    label: p.label,
                    caption: p.caption,
                    confidence: p.labelConfidence,
                    photoUrl: p.url,
                    timestamp: p.capturedAt,
                    latitude: p.latitude,
                    longitude: p.longitude,
                    damageType: p.damageType,
                    note: p.note,
                    sourceType: p.sourceType,
                    captureDevice: p.captureDevice,
                  ))
              .toList();
          sections[entry.key] = list;
        }
        structs.add(InspectedStructure(name: struct.name, sectionPhotos: sections));
      }
    }

    final metadataMap = {
      'clientName': widget.metadata.clientName,
      'propertyAddress': widget.metadata.propertyAddress,
      'inspectionDate': widget.metadata.inspectionDate.toIso8601String(),
      'insuranceCarrier': widget.metadata.insuranceCarrier,
      'perilType': widget.metadata.perilType.name,
      'inspectionType': widget.metadata.inspectionType.name,
      'inspectorRole': widget.metadata.inspectorRole.name,
      if (profile?.name != null)
        'inspectorName': profile!.name
      else 'inspectorName': widget.metadata.inspectorName,
      if (widget.metadata.reportId != null)
        'reportId': widget.metadata.reportId,
      if (widget.metadata.weatherNotes != null)
        'weatherNotes': widget.metadata.weatherNotes,
      if (widget.metadata.lastSentTo != null)
        'lastSentTo': widget.metadata.lastSentTo,
      if (widget.metadata.lastSentAt != null)
        'lastSentAt': widget.metadata.lastSentAt!.toIso8601String(),
      if (widget.metadata.lastSendMethod != null)
        'lastSendMethod': widget.metadata.lastSendMethod,
      if (widget.metadata.partnerCode != null)
        'partnerCode': widget.metadata.partnerCode,
      if (widget.metadata.startTimestamp != null)
        'startTimestamp': widget.metadata.startTimestamp!.toIso8601String(),
      if (widget.metadata.startLatitude != null)
        'startLatitude': widget.metadata.startLatitude,
      if (widget.metadata.startLongitude != null)
        'startLongitude': widget.metadata.startLongitude,
      'endTimestamp': DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    ReportTheme theme = ReportTheme.defaultTheme;
    final themeData = prefs.getString('report_theme');
    if (themeData != null) {
      theme =
          ReportTheme.fromMap(jsonDecode(themeData) as Map<String, dynamic>);
    }

    double? latitude;
    double? longitude;
    final gps = _gpsPhotos();
    if (gps.isNotEmpty) {
      latitude = gps.first.latitude;
      longitude = gps.first.longitude;
    }

    String? sigData;
    if (_signature != null) {
      sigData = 'data:image/png;base64,${base64Encode(_signature!)}';
    }

    final savedAttachments = List<ReportAttachment>.from(_attachments);

    final version = (_savedReport?.version ?? 0) + 1;
    final saved = SavedReport(
      id: id,
      version: version,
      userId: profile?.id,
      inspectionMetadata: metadataMap,
      structures: structs,
      summary: widget.summary,
      summaryText: _summaryTextController.text,
      signature: sigData,
      theme: theme,
      templateId: widget.template?.id,
      clientEmail: _emailController.text.isNotEmpty ? _emailController.text : null,
      partnerId: _partner?.id,
      referralDate: _partner != null ? DateTime.now() : null,
      lastAuditPassed: null,
      lastAuditIssues: null,
      signatureRequested: false,
      signatureStatus: 'none',
      reportOwner: profile?.id,
      collaborators: profile != null
          ? [
              ReportCollaborator(
                  id: profile.id,
                  name: profile.name,
                  role: CollaboratorRole.lead)
            ]
          : const [],
      lastEditedBy: profile?.id,
      lastEditedAt: DateTime.now(),
      latitude: latitude,
      longitude: longitude,
      jobCost: _jobCost,
      attachments: savedAttachments,
      localOnly: true,
    );

    await OfflineSyncService.instance.saveDraft(saved);

    setState(() {
      _saving = false;
      _docId = id;
      _savedReport = saved;
      _finalized = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report saved locally')),
      );
    }
  }

  Future<void> _reSign() async {
    if (_finalized) return;
    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => const CaptureSignatureScreen()),
    );
    if (result != null) {
      setState(() {
        _signature = result;
        _signatureLocked = false;
      });
    }
  }

  Future<void> _lockSignature() async {
    if (_signature == null || _finalized) return;
    await SignatureStorage.save(_signature!);
    setState(() {
      _signatureLocked = true;
    });
  }

  String get _publicUrl => 'https://clearsky.app/report/$_publicId';

  Future<void> _copyLink() async {
    if (_publicId == null) return;
    await Clipboard.setData(ClipboardData(text: _publicUrl));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Link copied')));
    }
  }

  void _openLink() {
    if (_publicId == null) return;
    final uri = Uri.parse(_publicUrl);
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _printCoverSheet() async {
    if (_publicId == null) return;
    final m = widget.metadata;
    final pdf = await generateQrCoverSheet(
      url: _publicUrl,
      propertyAddress: m.propertyAddress,
      clientName: m.clientName,
      inspectionDate: m.inspectionDate,
    );
    await Printing.layoutPdf(onLayout: (_) => pdf);
  }

  Future<void> _autoGenerateSummary() async {
    final metaMap = {
      'clientName': widget.metadata.clientName,
      'propertyAddress': widget.metadata.propertyAddress,
      'inspectionDate': widget.metadata.inspectionDate.toIso8601String(),
      'insuranceCarrier': widget.metadata.insuranceCarrier,
      'perilType': widget.metadata.perilType.name,
      'inspectionType': widget.metadata.inspectionType.name,
      'inspectorRole': widget.metadata.inspectorRole.name,
      'inspectorName': widget.metadata.inspectorName,
      if (widget.metadata.reportId != null)
        'reportId': widget.metadata.reportId,
      if (widget.metadata.weatherNotes != null)
        'weatherNotes': widget.metadata.weatherNotes,
      if (widget.metadata.lastSentTo != null)
        'lastSentTo': widget.metadata.lastSentTo,
      if (widget.metadata.lastSentAt != null)
        'lastSentAt': widget.metadata.lastSentAt!.toIso8601String(),
      if (widget.metadata.lastSendMethod != null)
        'lastSendMethod': widget.metadata.lastSendMethod,
    };
    final report = SavedReport(
      inspectionMetadata: metaMap,
      structures: widget.structures ?? [],
      summary: widget.summary,
      summaryText: _summaryTextController.text,
      version: _savedReport?.version ?? 1,
      latitude: _gpsPhotos().isNotEmpty ? _gpsPhotos().first.latitude : null,
      longitude: _gpsPhotos().isNotEmpty ? _gpsPhotos().first.longitude : null,
    );
    final key = const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '')
        .isNotEmpty
        ? const String.fromEnvironment('OPENAI_API_KEY')
        : (Platform.environment['OPENAI_API_KEY'] ?? '');
    String text;
    if (key.isNotEmpty) {
      try {
        final svc = AiSummaryService(apiKey: key);
        final result = await svc.generateSummary(report);
        text = result.adjuster;
      } catch (_) {
        text = generateSummaryText(report);
      }
    } else {
      text = generateSummaryText(report);
    }
    setState(() {
      _summaryTextController.text = text;
      if (_savedReport != null) {
        _savedReport = SavedReport(
          id: _savedReport!.id,
          version: _savedReport!.version,
          userId: _savedReport!.userId,
          inspectionMetadata: _savedReport!.inspectionMetadata,
          structures: _savedReport!.structures,
          summary: _savedReport!.summary,
          summaryText: text,
          signature: _savedReport!.signature,
          createdAt: _savedReport!.createdAt,
          isFinalized: _savedReport!.isFinalized,
          publicReportId: _savedReport!.publicReportId,
          clientEmail: _savedReport!.clientEmail,
          templateId: _savedReport!.templateId,
          lastAuditPassed: _savedReport!.lastAuditPassed,
          lastAuditIssues: _savedReport!.lastAuditIssues,
          reportOwner: _savedReport!.reportOwner,
          collaborators: _savedReport!.collaborators,
          lastEditedBy: _savedReport!.lastEditedBy,
          lastEditedAt: _savedReport!.lastEditedAt,
          latitude: _savedReport!.latitude,
          longitude: _savedReport!.longitude,
          attachments: _savedReport!.attachments,
        );
      }
    });
  }

  void _downloadPdf() {
    // TODO: reuse _downloadPdf from ReportPreviewScreen
  }

  void _downloadHtml() {
    // TODO: reuse _saveHtmlFile logic
  }

  Future<void> _exportCsv() async {
    if (_savedReport == null || _exporting) return;
    await _maybeRunQualityCheck();
    if (!canEditReport(_savedReport!, _profile)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Permission denied')));
      return;
    }
    setState(() => _exporting = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
    try {
      final file = await exportCsv(_savedReport!);
      if (mounted) {
        setState(() => _exportedFile = file);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV exported')),
        );
      }
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportZip() async {
    if (_savedReport == null || _exporting) return;
    await _maybeRunQualityCheck();
    if (!canEditReport(_savedReport!, _profile)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Permission denied')));
      return;
    }
    if (!inspectionChecklist.allRequiredComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checklist incomplete')),
      );
      return;
    }
    setState(() => _exporting = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 60,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
    try {
      final file = await exportFinalZip(_savedReport!);
      if (mounted) {
        setState(() => _exportedFile = file);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ZIP exported')),
        );
        inspectionChecklist.markComplete('Report Exported');
        LocalReportStore.instance.saveSnapshot(_savedReport!);
      }
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportLegal() async {
    if (_savedReport == null || _exporting) return;
    await _maybeRunQualityCheck();
    if (_profile?.role != InspectorRole.admin) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Admin only')));
      return;
    }
    setState(() => _exporting = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 60,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
    try {
      final file = await exportLegalCopy(_savedReport!, userId: _profile?.id);
      if (mounted) {
        setState(() => _exportedFile = file);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Legal copy exported')),
        );
      }
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportAudio() async {
    if (_savedReport == null || _exporting) return;
    await _maybeRunQualityCheck();
    setState(() => _exporting = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = prefs.getString('report_settings');
      ReportSettings? settings;
      if (map != null) {
        settings = ReportSettings.fromMap(jsonDecode(map));
      }
      final intro = TtsService.instance.settings.brandingMessage.isNotEmpty
          ? TtsService.instance.settings.brandingMessage
          :
              'This report is provided by ${settings?.companyName ?? 'ClearSky'}.'
              ' ${settings?.tagline ?? ''}';
      final outro = 'Thank you for choosing ${settings?.companyName ?? 'ClearSky'}.';
      final file = await TtsService.instance.exportSummary(
          _summaryTextController.text, intro, outro);
      if (mounted) {
        setState(() => _audioFile = file);
        try {
          _audioUrl = await uploadAudioFile(file);
        } catch (_) {
          _audioUrl = null;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio exported')),
        );
      }
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _shareAudio() async {
    if (_audioFile == null) return;
    if (_audioUrl != null) {
      await Share.share('Listen: $_audioUrl');
      return;
    }
    await shareReportFile(_audioFile!, subject: 'Inspection Summary');
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'csv'],
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = p.basename(path);
      final tagController = TextEditingController(text: name);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Add Attachment'),
          content: TextField(
            controller: tagController,
            decoration: const InputDecoration(labelText: 'Label'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        setState(() {
          _attachments.add(ReportAttachment(
            name: name,
            url: path,
            tag: tagController.text,
            type: p.extension(path).replaceFirst('.', ''),
          ));
        });
      }
    }
  }

  Future<void> _runQualityCheck() async {
    if (_savedReport == null) return;
    final result = await aiQualityCheck(_savedReport!);
    if (_docId != null) {
      try {
        await FirebaseFirestore.instance.collection('reports').doc(_docId).update({
          'lastAuditPassed': result.passed,
          'lastAuditIssues': result.issues.map((e) => e.toMap()).toList(),
        });
      } catch (_) {}
    }
    setState(() {
      _auditPassed = result.passed;
      _auditIssues = result.issues;
    });
    _showAuditDialog();
  }

  void _showAuditDialog() {
    if (_auditPassed == null) return;
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title:
              Text(_auditPassed! ? 'Quality Check Passed' : 'Quality Check Issues'),
          content: _auditPassed!
              ? const Text('No issues found.')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _auditIssues.length,
                    itemBuilder: (context, index) {
                      final issue = _auditIssues[index];
                      return ListTile(
                        leading: Image.network(issue.photo.photoUrl,
                            width: 56, height: 56, fit: BoxFit.cover),
                        title: Text(issue.issue),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${issue.structure} - ${issue.section}'),
                            if (issue.suggestion != null)
                              Text('Suggestion: ${issue.suggestion!}',
                                  style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareReport() async {
    if (_exportedFile == null) return;
    await _maybeRunQualityCheck();
    final m = widget.metadata;
    final subject = 'Roof Inspection Report for ${m.clientName}';
    final inspector = m.inspectorName != null ? ' by ${m.inspectorName}' : '';
    final body = 'Attached is the roof inspection report for ${m.clientName}$inspector.';
    await shareReportFile(_exportedFile!, subject: subject, text: body);
  }

  Future<void> _assignClientEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _docId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(_docId)
          .update({'clientEmail': email});
      await AuditLogService().logAction('assign_client', targetId: _docId);
      await AuthService().sendSignInLink(email, Uri.base.toString());
      if (_savedReport != null) {
        setState(() {
          _savedReport = SavedReport(
            id: _savedReport!.id,
            version: _savedReport!.version,
            userId: _savedReport!.userId,
            inspectionMetadata: _savedReport!.inspectionMetadata,
            structures: _savedReport!.structures,
            summary: _savedReport!.summary,
            summaryText: _savedReport!.summaryText,
            signature: _savedReport!.signature,
            createdAt: _savedReport!.createdAt,
            isFinalized: _savedReport!.isFinalized,
            publicReportId: _savedReport!.publicReportId,
            clientEmail: email,
            templateId: _savedReport!.templateId,
            lastAuditPassed: _savedReport!.lastAuditPassed,
            lastAuditIssues: _savedReport!.lastAuditIssues,
            changeLog: _savedReport!.changeLog,
            snapshots: _savedReport!.snapshots,
            reportOwner: _savedReport!.reportOwner,
            collaborators: _savedReport!.collaborators,
            lastEditedBy: _savedReport!.lastEditedBy,
            lastEditedAt: _savedReport!.lastEditedAt,
            latitude: _savedReport!.latitude,
            longitude: _savedReport!.longitude,
          );
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Client invited')));
      }
    } catch (_) {}
  }

  Future<void> _openEmailDialog() async {
    final toCtrl = TextEditingController(text: _emailController.text);
    final m = widget.metadata;
    final subjectCtrl = TextEditingController(
        text: 'Roof Inspection Report for ${m.clientName}');
    final inspector = m.inspectorName != null ? ' by ${m.inspectorName}' : '';
    String defaultMessage =
        'Please find attached the roof inspection report for ${m.clientName}$inspector.';
    String signature = '';
    bool attachPdf = true;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('report_settings');
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final settings = ReportSettings.fromMap(map);
      defaultMessage = settings.emailMessage.isNotEmpty
          ? settings.emailMessage
              .replaceAll('{client}', m.clientName)
              .replaceAll('{inspector}', m.inspectorName ?? '')
          : defaultMessage;
      signature = settings.emailSignature;
      attachPdf = settings.attachPdf;
    }
    final bodyCtrl = TextEditingController(text: defaultMessage);

    final send = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: toCtrl,
              decoration: const InputDecoration(labelText: 'To'),
            ),
            TextField(
              controller: subjectCtrl,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          )
        ],
      ),
    );

    if (send == true) {
      await _sendEmail(
          toCtrl.text, subjectCtrl.text, bodyCtrl.text, signature, attachPdf);
    }
  }

  Future<void> _sendEmail(
      String to, String subject, String body, String signature, bool attachPdf) async {
    if (to.isEmpty || _savedReport == null) return;
    await _maybeRunQualityCheck();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
    try {
      final pdf = await generatePdf(_savedReport!);
      await sendReportEmail(to, pdf,
          subject: subject,
          message: body,
          signature: signature,
          attachPdf: attachPdf,
          attachments: _attachments);
      if (_docId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('reports')
              .doc(_docId)
              .update({
            'clientEmail': to,
            'inspectionMetadata.lastSentTo': to,
            'inspectionMetadata.lastSentAt': FieldValue.serverTimestamp(),
            'inspectionMetadata.lastSendMethod': attachPdf ? 'attachment' : 'link',
          });
        } catch (_) {}
      }
      try {
        await AuthService().sendSignInLink(to, Uri.base.toString());
        await AuditLogService().logAction('invite_client', targetId: _docId);
      } catch (_) {}
      final meta = Map<String, dynamic>.from(_savedReport!.inspectionMetadata);
      meta['lastSentTo'] = to;
      meta['lastSentAt'] = DateTime.now().toIso8601String();
      meta['lastSendMethod'] = attachPdf ? 'attachment' : 'link';
      setState(() {
        _savedReport = SavedReport(
          id: _savedReport!.id,
          version: _savedReport!.version,
          userId: _savedReport!.userId,
          inspectionMetadata: meta,
          structures: _savedReport!.structures,
          summary: _savedReport!.summary,
          summaryText: _savedReport!.summaryText,
          signature: _savedReport!.signature,
          createdAt: _savedReport!.createdAt,
          isFinalized: _savedReport!.isFinalized,
          publicReportId: _savedReport!.publicReportId,
          clientEmail: to,
          templateId: _savedReport!.templateId,
          lastAuditPassed: _savedReport!.lastAuditPassed,
          lastAuditIssues: _savedReport!.lastAuditIssues,
          changeLog: _savedReport!.changeLog,
          snapshots: _savedReport!.snapshots,
          reportOwner: _savedReport!.reportOwner,
          collaborators: _savedReport!.collaborators,
          lastEditedBy: _savedReport!.lastEditedBy,
          lastEditedAt: _savedReport!.lastEditedAt,
          latitude: _savedReport!.latitude,
          longitude: _savedReport!.longitude,
          attachments: _savedReport!.attachments,
        );
      });
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _finalizeReport() async {
    if (_savedReport == null || _finalized) return;
    if (!canEditReport(_savedReport!, _profile)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Permission denied')));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalize Report'),
        content: const Text(
            'Lock this report and prevent any further edits?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalize'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    String publicId =
        FirebaseFirestore.instance.collection('publicReports').doc().id;
    final viewLink = 'https://clearsky.app/report/$publicId';
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(_docId)
          .update({
            'isFinalized': true,
            'publicReportId': publicId,
            'publicViewLink': viewLink,
            'publicViewEnabled': _publicLinkEnabled,
            if (_passwordController.text.isNotEmpty)
              'publicViewPassword': _passwordController.text,
            if (_expiryDate != null)
              'publicViewExpiry': Timestamp.fromDate(_expiryDate!),
            'summaryText': _summaryTextController.text,
            'signatureRequested': _requestSignature,
            'signatureStatus': _requestSignature ? 'pending' : 'none'
          });
      final metricsRef =
          FirebaseFirestore.instance.collection('metrics').doc(_docId);
      final metricSnap = await metricsRef.get();
      final createdRaw = metricSnap.data()?['createdAt'];
      int? createdMs;
      if (createdRaw is Timestamp) {
        createdMs = createdRaw.millisecondsSinceEpoch;
      } else if (createdRaw is int) {
        createdMs = createdRaw;
      }
      await metricsRef.update({
        'finalizedAt': FieldValue.serverTimestamp(),
        'status': 'finalized',
        if (createdMs != null)
          'durationMillis': DateTime.now().millisecondsSinceEpoch - createdMs,
      });
    } catch (_) {}

    setState(() {
      _finalized = true;
      _publicId = publicId;
      if (_savedReport != null) {
        _savedReport = SavedReport(
          id: _savedReport!.id,
          version: _savedReport!.version + 1,
          userId: _savedReport!.userId,
          inspectionMetadata: _savedReport!.inspectionMetadata,
          structures: _savedReport!.structures,
          summary: _savedReport!.summary,
          summaryText: _summaryTextController.text,
          signature: _savedReport!.signature,
          createdAt: _savedReport!.createdAt,
          isFinalized: true,
          signatureRequested: _requestSignature,
          signatureStatus: _requestSignature ? 'pending' : 'none',
          publicReportId: publicId,
          publicViewLink: viewLink,
          publicViewEnabled: _publicLinkEnabled,
          publicViewPassword:
              _passwordController.text.isNotEmpty
                  ? _passwordController.text
                  : null,
          publicViewExpiry: _expiryDate,
          clientEmail: _savedReport!.clientEmail,
          templateId: _savedReport!.templateId,
          lastAuditPassed: _savedReport!.lastAuditPassed,
          lastAuditIssues: _savedReport!.lastAuditIssues,
          changeLog: _savedReport!.changeLog,
          snapshots: _savedReport!.snapshots,
          reportOwner: _savedReport!.reportOwner,
          collaborators: _savedReport!.collaborators,
          lastEditedBy: _savedReport!.lastEditedBy,
          lastEditedAt: _savedReport!.lastEditedAt,
          latitude: _savedReport!.latitude,
          longitude: _savedReport!.longitude,
          attachments: _savedReport!.attachments,
        );
      }
    });

    if (_savedReport != null) {
      LocalReportStore.instance.saveSnapshot(_savedReport!);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('report_settings');
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final settings = ReportSettings.fromMap(map);
        if (settings.autoLegalBackup) {
          await exportLegalCopy(_savedReport!,
              userId: _profile?.id, auto: true);
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report finalized')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metadata;
    return Scaffold(
      appBar: AppBar(title: const Text('Send Report')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_savedReport?.lastEditedBy != null &&
                _savedReport!.lastEditedBy != _profile?.id)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.orangeAccent,
                child: Text(
                  '${_savedReport!.collaborators.firstWhere(
                        (c) => c.id == _savedReport!.lastEditedBy,
                        orElse: () => ReportCollaborator(
                            id: _savedReport!.lastEditedBy!,
                            name: _savedReport!.lastEditedBy!,
                            role: CollaboratorRole.viewer),
                      ).name} editing...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            if (_finalized)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.redAccent,
                child: const Text(
                  'FINALIZED',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client: ${m.clientName}'),
                    Text('Address: ${m.propertyAddress}'),
                    Text('Date: ${m.inspectionDate.toLocal().toString().split(' ')[0]}'),
                    if (widget.summary != null && widget.summary!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Inspector Notes / Summary:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(widget.summary!),
                    ],
                  ],
                ),
              ),
            ),
            if (_signature != null) ...[
              const SizedBox(height: 12),
              Image.memory(_signature!, height: 100),
              if (!_signatureLocked && !_finalized) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _reSign,
                      child: const Text('Re-sign'),
                    ),
                    ElevatedButton(
                      onPressed: _lockSignature,
                      child: const Text('Use This Signature'),
                    ),
                  ],
                ),
              ],
            ],
            TextField(
              controller: _summaryTextController,
              decoration: const InputDecoration(
                  labelText: 'Summary of Findings'),
              maxLines: 3,
            ),
            TextField(
              decoration:
                  const InputDecoration(labelText: 'Estimated Job Cost'),
              onChanged: (v) => _jobCost = v,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _autoGenerateSummary,
              child: const Text('Auto-Generate'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _exportAudio,
              child: const Text('Export Audio Summary'),
            ),
            if (_audioFile != null)
              ElevatedButton(
                onPressed: _shareAudio,
                child: const Text('Share Audio'),
              ),
            const SizedBox(height: 12),
            const Text('Attach 3rd-Party Reports',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ..._attachments.map(
              (a) => ListTile(
                title: Text(a.tag.isNotEmpty ? a.tag : a.name),
                subtitle: Text(a.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _attachments.remove(a);
                    });
                  },
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _pickAttachment,
              icon: const Icon(Icons.attach_file),
              label: const Text('Add Attachment'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Client Email'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _assignClientEmail,
              child: const Text('Assign Client'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    onPressed: _downloadPdf,
                    child: const Text('Download PDF')),
                ElevatedButton(
                    onPressed: _downloadHtml,
                    child: const Text('Download HTML')),
                ElevatedButton(
                    onPressed: _exporting ? null : _exportCsv,
                    child: _exporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Export CSV')),
                ElevatedButton(
                    onPressed: _exporting ? null : _exportZip,
                    child: _exporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Download ZIP')),
                if (_profile?.role == InspectorRole.admin)
                  ElevatedButton(
                      onPressed: _exporting ? null : _exportLegal,
                      child: _exporting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Export Legal Copy')),
              if (_exportedFile != null)
                ElevatedButton(
                    onPressed: _shareReport,
                    child: const Text('Share Report')),
              ElevatedButton(
                  onPressed: _runQualityCheck,
                  child: const Text('Run AI Quality Check')),
              ],
            ),
            if (_gpsPhotos().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoMapScreen(photos: _gpsPhotos()),
                      ),
                    );
                  },
                  child: const Text('View Inspection Map'),
                ),
              ),
            if (_finalized && _publicId != null) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Client Share Link',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Center(
                        child: QrImage(
                          data: _publicUrl,
                          size: 160,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(_publicUrl, textAlign: TextAlign.center),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _copyLink,
                            tooltip: 'Copy Link',
                            icon: const Icon(Icons.copy),
                          ),
                          IconButton(
                            onPressed: _openLink,
                            tooltip: 'Open Link',
                            icon: const Icon(Icons.open_in_browser),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _printCoverSheet,
                        child: const Text('Print QR Cover Sheet'),
                      )
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateInvoiceScreen(
                      reportId: _savedReport?.id ?? _docId!,
                      clientName: m.clientName,
                    ),
                  ),
                );
              },
              child: const Text('Create Invoice'),
            ),
            ],
            if (!_finalized)
              SwitchListTile(
                title: const Text('Request Homeowner Signature'),
                value: _requestSignature,
                onChanged: (val) {
                  setState(() {
                    _requestSignature = val;
                  });
                },
              ),
            if (!_finalized) ...[
              SwitchListTile(
                title: const Text('Enable Public View'),
                value: _publicLinkEnabled,
                onChanged: (val) {
                  setState(() {
                    _publicLinkEnabled = val;
                  });
                },
              ),
              TextField(
                controller: _passwordController,
                decoration:
                    const InputDecoration(labelText: 'Password (optional)'),
              ),
              Row(
                children: [
                  const Text('Expiry: '),
                  Expanded(
                    child: Text(_expiryDate == null
                        ? 'none'
                        : _expiryDate!
                            .toLocal()
                            .toString()
                            .split(' ')[0]),
                  ),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 5),
                      );
                      if (picked != null) {
                        setState(() => _expiryDate = picked);
                      }
                    },
                    child: const Text('Select'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (!_finalized)
              ElevatedButton(
                onPressed: _finalizeReport,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('Finalize & Lock Report'),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _savedReport == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChangeHistoryScreen(report: _savedReport!),
                        ),
                      );
                    },
              child: const Text('View History'),
            ),
            const SizedBox(height: 12),
            if (_savedReport != null)
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push<List<ReportCollaborator>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ManageCollaboratorsScreen(report: _savedReport!),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _savedReport = SavedReport(
                        id: _savedReport!.id,
                        version: _savedReport!.version,
                        userId: _savedReport!.userId,
                        inspectionMetadata: _savedReport!.inspectionMetadata,
                        structures: _savedReport!.structures,
                        summary: _savedReport!.summary,
                        summaryText: _savedReport!.summaryText,
                        signature: _savedReport!.signature,
                        createdAt: _savedReport!.createdAt,
                        isFinalized: _savedReport!.isFinalized,
                        publicReportId: _savedReport!.publicReportId,
                        clientEmail: _savedReport!.clientEmail,
                        templateId: _savedReport!.templateId,
                        lastAuditPassed: _savedReport!.lastAuditPassed,
                        lastAuditIssues: _savedReport!.lastAuditIssues,
                        changeLog: _savedReport!.changeLog,
                        snapshots: _savedReport!.snapshots,
                        reportOwner: _savedReport!.reportOwner,
                        collaborators: result,
                        lastEditedBy: _savedReport!.lastEditedBy,
                        lastEditedAt: _savedReport!.lastEditedAt,
                        latitude: _savedReport!.latitude,
                        longitude: _savedReport!.longitude,
                        attachments: _savedReport!.attachments,
                      );
                    });
                  }
                },
                child: const Text('Manage Collaborators'),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InspectionChecklistScreen(),
                ),
              ),
              child: const Text('View Checklist'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  _emailController.text.isEmpty ? null : _openEmailDialog,
              child: const Text('Send to Client'),
            ),
          ],
        ),
      ),
    );
  }
}
