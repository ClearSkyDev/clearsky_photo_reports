import 'dart:io';

import 'package:image/image.dart' as img;

import '../models/saved_report.dart';

class PhotoAuditIssue {
  final String structure;
  final String section;
  final String issue;
  final ReportPhotoEntry photo;
  final String? suggestion;

  PhotoAuditIssue({
    required this.structure,
    required this.section,
    required this.issue,
    required this.photo,
    this.suggestion,
  });

  Map<String, dynamic> toMap() => {
        'structure': structure,
        'section': section,
        'issue': issue,
        'photo': photo.toMap(),
        if (suggestion != null) 'suggestion': suggestion,
      };

  factory PhotoAuditIssue.fromMap(Map<String, dynamic> map) {
    return PhotoAuditIssue(
      structure: map['structure'] as String? ?? '',
      section: map['section'] as String? ?? '',
      issue: map['issue'] as String? ?? '',
      photo:
          ReportPhotoEntry.fromMap(Map<String, dynamic>.from(map['photo'] ?? {})),
      suggestion: map['suggestion'] as String?,
    );
  }
}

class PhotoAuditResult {
  final bool passed;
  final List<PhotoAuditIssue> issues;

  PhotoAuditResult({required this.passed, required this.issues});
}

/// Runs a basic audit on [report] photos.
///
/// Checks for missing labels or notes, potential duplicate photos based on
/// GPS coordinates or timestamps, low resolution images and missing elevation
/// sections. This is a placeholder implementation that can be extended with
/// ML-based similarity and blur detection.
Future<PhotoAuditResult> photoAudit(SavedReport report) async {
  final issues = <PhotoAuditIssue>[];

  final elevationSections = {
    'Front Elevation & Accessories',
    'Right Elevation & Accessories',
    'Back Elevation & Accessories',
    'Left Elevation & Accessories',
  };

  final all = <_EntryInfo>[];

  for (final struct in report.structures) {
    for (final entry in struct.sectionPhotos.entries) {
      if (elevationSections.contains(entry.key) && entry.value.isEmpty) {
        issues.add(PhotoAuditIssue(
          structure: struct.name,
          section: entry.key,
          issue: 'Missing required elevation photos',
          photo: ReportPhotoEntry(
            label: '',
            caption: '',
            confidence: 0,
            photoUrl: '',
            timestamp: null),
        ));
      }
      for (final photo in entry.value) {
        all.add(_EntryInfo(photo, struct.name, entry.key));
        if (photo.label.isEmpty) {
          issues.add(PhotoAuditIssue(
            structure: struct.name,
            section: entry.key,
            issue: 'Missing label',
            photo: photo,
          ));
        }
        if (photo.caption.isEmpty) {
          issues.add(PhotoAuditIssue(
            structure: struct.name,
            section: entry.key,
            issue: 'Missing caption',
            photo: photo,
          ));
        }
        if (photo.note.isEmpty) {
          issues.add(PhotoAuditIssue(
            structure: struct.name,
            section: entry.key,
            issue: 'Missing inspector note',
            photo: photo,
          ));
        }
        // Low resolution check using image package
        try {
          final file = File(photo.photoUrl);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final decoded = img.decodeImage(bytes);
            if (decoded != null && (decoded.width < 800 || decoded.height < 600)) {
              issues.add(PhotoAuditIssue(
                structure: struct.name,
                section: entry.key,
                issue:
                    'Low resolution (${decoded.width}x${decoded.height})',
                photo: photo,
              ));
            }
            // Blur detection using variance of Sobel filter
            if (decoded != null) {
              final score = _blurScore(decoded);
              if (score < 20) {
                issues.add(PhotoAuditIssue(
                  structure: struct.name,
                  section: entry.key,
                  issue: 'Blurry or unclear image',
                  photo: photo,
                ));
              }
            }
          }
        } catch (_) {}
      }
    }
  }

  // Duplicate detection based on GPS or timestamp
  for (var i = 0; i < all.length; i++) {
    final a = all[i];
    for (var j = i + 1; j < all.length; j++) {
      final b = all[j];
      bool duplicate = false;
      if (a.photo.latitude != null &&
          a.photo.longitude != null &&
          b.photo.latitude != null &&
          b.photo.longitude != null) {
        final dLat = (a.photo.latitude! - b.photo.latitude!).abs();
        final dLng = (a.photo.longitude! - b.photo.longitude!).abs();
        if (dLat < 0.0001 && dLng < 0.0001) {
          duplicate = true;
        }
      }
      if (!duplicate && a.photo.timestamp != null && b.photo.timestamp != null) {
        final diff = a.photo.timestamp!.difference(b.photo.timestamp!).inSeconds.abs();
        if (diff <= 2) duplicate = true;
      }
      if (duplicate) {
        issues.add(PhotoAuditIssue(
          structure: b.structure,
          section: b.section,
          issue: 'Possible duplicate photo',
          photo: b.photo,
        ));
      }
    }
  }

  return PhotoAuditResult(passed: issues.isEmpty, issues: issues);
}

class _EntryInfo {
  final ReportPhotoEntry photo;
  final String structure;
  final String section;

  _EntryInfo(this.photo, this.structure, this.section);
}

double _blurScore(img.Image image) {
  final gray = img.grayscale(image);
  final sobel = img.sobel(gray);
  double mean = 0;
  for (final p in sobel.data) {
    mean += (p & 0xFF);
  }
  mean /= sobel.length;
  double variance = 0;
  for (final p in sobel.data) {
    final v = (p & 0xFF) - mean;
    variance += v * v;
  }
  return variance / sobel.length;
}

