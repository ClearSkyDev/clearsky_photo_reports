import 'inspected_structure.dart';

// Model for persisting completed reports in Firestore
import 'report_theme.dart';
import '../utils/photo_audit.dart';
import 'report_change.dart';
import 'report_snapshot.dart';
import 'report_collaborator.dart';
import 'homeowner_signature.dart';
import 'photo_entry.dart' show SourceType;
import 'ai_summary.dart';
import 'report_attachment.dart';

class SavedReport {
  final String id;
  final int version;
  final String? userId;
  final Map<String, dynamic> inspectionMetadata;
  final List<InspectedStructure> structures;
  final String? summary;
  /// Paragraph summarizing the overall findings.
  final String? summaryText;
  /// Draft AI-generated summary review information.
  final AiSummaryReview? aiSummary;
  /// Either a download URL or base64 encoded PNG of the inspector signature.
  final String? signature;
  /// Random ID used for public sharing of the report.
  final String? publicReportId;
  /// Fully qualified URL that clients can use to view the report.
  final String? publicViewLink;
  final bool publicViewEnabled;
  final String? publicViewPassword;
  final DateTime? publicViewExpiry;
  /// Email address associated with the client portal account.
  final String? clientEmail;
  final String? templateId;
  final DateTime createdAt;
  final bool isFinalized;
  final bool signatureRequested;
  final String signatureStatus; // pending, signed, declined, none
  final HomeownerSignature? homeownerSignature;
  final ReportTheme? theme;
  final bool? lastAuditPassed;
  final List<PhotoAuditIssue>? lastAuditIssues;
  final List<ReportChange> changeLog;
  final List<ReportSnapshot> snapshots;
  final List<ReportAttachment> attachments;
  final String? reportOwner;
  final List<ReportCollaborator> collaborators;
  final String? lastEditedBy;
  final DateTime? lastEditedAt;
  final String? jobCost;
  final String? partnerId;
  final DateTime? referralDate;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? searchIndex;
  final bool localOnly;

  SavedReport({
    this.id = '',
    this.version = 1,
    this.userId,
    required this.inspectionMetadata,
    required this.structures,
    this.summary,
    this.summaryText,
    this.aiSummary,
    this.signature,
    this.publicReportId,
    this.publicViewLink,
    this.publicViewEnabled = true,
    this.publicViewPassword,
    this.publicViewExpiry,
    this.templateId,
    this.clientEmail,
    DateTime? createdAt,
    this.isFinalized = false,
    this.signatureRequested = false,
    this.signatureStatus = 'none',
    this.homeownerSignature,
    this.theme,
    this.lastAuditPassed,
    this.lastAuditIssues,
    this.changeLog = const [],
    this.snapshots = const [],
    this.attachments = const [],
    this.reportOwner,
    this.collaborators = const [],
    this.lastEditedBy,
    this.lastEditedAt,
    this.jobCost,
    this.partnerId,
    this.referralDate,
    this.latitude,
    this.longitude,
    this.searchIndex,
    this.localOnly = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'inspectionMetadata': inspectionMetadata,
      'structures': structures.map((s) => s.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isFinalized': isFinalized,
      if (userId != null) 'userId': userId,
      if (summary != null) 'summary': summary,
      if (summaryText != null) 'summaryText': summaryText,
      if (aiSummary != null) 'aiSummary': aiSummary!.toMap(),
      if (signature != null) 'signature': signature,
      if (publicReportId != null) 'publicReportId': publicReportId,
      if (publicViewLink != null) 'publicViewLink': publicViewLink,
      'publicViewEnabled': publicViewEnabled,
      if (publicViewPassword != null) 'publicViewPassword': publicViewPassword,
      if (publicViewExpiry != null)
        'publicViewExpiry': publicViewExpiry!.millisecondsSinceEpoch,
      if (templateId != null) 'templateId': templateId,
      if (clientEmail != null) 'clientEmail': clientEmail,
      'signatureRequested': signatureRequested,
      'signatureStatus': signatureStatus,
      if (homeownerSignature != null)
        'homeownerSignature': homeownerSignature!.toMap(),
      if (theme != null) 'theme': theme!.toMap(),
      if (lastAuditPassed != null) 'lastAuditPassed': lastAuditPassed,
      if (lastAuditIssues != null)
        'lastAuditIssues': lastAuditIssues!.map((e) => e.toMap()).toList(),
      if (changeLog.isNotEmpty)
        'changeLog': changeLog.map((e) => e.toMap()).toList(),
      if (snapshots.isNotEmpty)
        'snapshots': snapshots.map((e) => e.toMap()).toList(),
      if (attachments.isNotEmpty)
        'attachments': attachments.map((e) => e.toMap()).toList(),
      if (reportOwner != null) 'reportOwner': reportOwner,
      if (collaborators.isNotEmpty)
        'collaborators': collaborators.map((e) => e.toMap()).toList(),
      if (lastEditedBy != null) 'lastEditedBy': lastEditedBy,
      if (lastEditedAt != null)
        'lastEditedAt': lastEditedAt!.millisecondsSinceEpoch,
      if (jobCost != null) 'jobCost': jobCost,
      if (partnerId != null) 'partnerId': partnerId,
      if (referralDate != null)
        'referralDate': referralDate!.millisecondsSinceEpoch,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (searchIndex != null) 'searchIndex': searchIndex,
      'version': version,
      if (localOnly) 'localOnly': true,
    };
  }

  factory SavedReport.fromMap(Map<String, dynamic> map, String id) {
    final structs = <InspectedStructure>[];
    final rawStructs = map['structures'] as List<dynamic>? ?? [];
    for (final item in rawStructs) {
      structs.add(
          InspectedStructure.fromMap(Map<String, dynamic>.from(item as Map)));
    }

    return SavedReport(
      id: id,
      userId: map['userId'] as String?,
      inspectionMetadata:
          Map<String, dynamic>.from(map['inspectionMetadata'] ?? {}),
      structures: structs,
      summary: map['summary'] as String?,
      summaryText: map['summaryText'] as String?,
      aiSummary: map['aiSummary'] != null
          ? AiSummaryReview.fromMap(
              Map<String, dynamic>.from(map['aiSummary']))
          : null,
      signature: map['signature'] as String?,
      publicReportId: map['publicReportId'] as String?,
      publicViewLink: map['publicViewLink'] as String?,
      publicViewEnabled: map['publicViewEnabled'] as bool? ?? true,
      publicViewPassword: map['publicViewPassword'] as String?,
      publicViewExpiry: map['publicViewExpiry'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['publicViewExpiry'])
          : null,
      clientEmail: map['clientEmail'] as String?,
      templateId: map['templateId'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      isFinalized: map['isFinalized'] as bool? ?? false,
      signatureRequested: map['signatureRequested'] as bool? ?? false,
      signatureStatus: map['signatureStatus'] as String? ?? 'none',
      homeownerSignature: map['homeownerSignature'] != null
          ? HomeownerSignature.fromMap(
              Map<String, dynamic>.from(map['homeownerSignature']))
          : null,
      theme: map['theme'] != null
          ? ReportTheme.fromMap(Map<String, dynamic>.from(map['theme']))
          : null,
      lastAuditPassed: map['lastAuditPassed'] as bool?,
      lastAuditIssues: map['lastAuditIssues'] != null
          ? (map['lastAuditIssues'] as List)
              .map((e) =>
                  PhotoAuditIssue.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList()
          : null,
      changeLog: map['changeLog'] != null
          ? (map['changeLog'] as List)
              .map((e) =>
                  ReportChange.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList()
          : [],
      snapshots: map['snapshots'] != null
          ? (map['snapshots'] as List)
              .map((e) =>
                  ReportSnapshot.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList()
          : [],
      attachments: map['attachments'] != null
          ? (map['attachments'] as List)
              .map((e) =>
                  ReportAttachment.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList()
          : [],
      reportOwner: map['reportOwner'] as String?,
      collaborators: map['collaborators'] != null
          ? (map['collaborators'] as List)
              .map((e) => ReportCollaborator.fromMap(
                  Map<String, dynamic>.from(e as Map)))
              .toList()
          : [],
      lastEditedBy: map['lastEditedBy'] as String?,
      lastEditedAt: map['lastEditedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastEditedAt'])
          : null,
      jobCost: map['jobCost'] as String?,
      partnerId: map['partnerId'] as String?,
      referralDate: map['referralDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['referralDate'])
          : null,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      searchIndex: map['searchIndex'] != null
          ? Map<String, dynamic>.from(map['searchIndex'])
          : null,
      version: map['version'] as int? ?? 1,
      localOnly: map['localOnly'] as bool? ?? false,
    );
  }
}

class ReportPhotoEntry {
  final String label;
  final String photoUrl;
  final DateTime? timestamp;
  final double? latitude;
  final double? longitude;
  final String damageType;
  final String note;
  final String? voicePath;
  final String? transcript;
  final SourceType sourceType;
  final String? captureDevice;

  ReportPhotoEntry({
    required this.label,
    required this.photoUrl,
    this.timestamp,
    this.latitude,
    this.longitude,
    this.damageType = 'Unknown',
    this.note = '',
    this.voicePath,
    this.transcript,
    this.sourceType = SourceType.camera,
    this.captureDevice,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'photoUrl': photoUrl,
      if (timestamp != null) 'timestamp': timestamp!.millisecondsSinceEpoch,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'damageType': damageType,
      if (note.isNotEmpty) 'note': note,
      if (voicePath != null) 'voicePath': voicePath,
      if (transcript != null) 'transcript': transcript,
      'sourceType': sourceType.name,
      if (captureDevice != null) 'captureDevice': captureDevice,
    };
  }

  factory ReportPhotoEntry.fromMap(Map<String, dynamic> map) {
    return ReportPhotoEntry(
      label: map['label'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
          : null,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      damageType: map['damageType'] as String? ?? 'Unknown',
      note: map['note'] as String? ?? '',
      voicePath: map['voicePath'] as String?,
      transcript: map['transcript'] as String?,
      sourceType: SourceType.values.firstWhere(
          (e) => e.name == map['sourceType'],
          orElse: () => SourceType.camera),
      captureDevice: map['captureDevice'] as String?,
    );
  }
}
