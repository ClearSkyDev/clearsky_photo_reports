/// Utilities for generating AI-based label suggestions.
///
/// Currently provides a placeholder [getSuggestedLabel] function that returns a
/// fake label for a photo. In the future this will call an AI service such as
/// OpenAI or a custom model.

import 'dart:math';
import 'dart:io';
import 'dart:convert';

import '../models/photo_entry.dart';
import '../models/inspection_metadata.dart';

final List<String> _fakeDescriptions = [
  'Hail impact near ridge',
  'Wind crease on shingle',
  'Loose flashing',
  'Missing fasteners',
  'Potential leak area',
];

/// Returns a fake suggested label for [photo] in the given [sectionName].
///
/// [metadata] provides additional context about the inspection that may be
/// leveraged by future AI models. Currently a random description is returned
/// after a short delay.
Future<String> getSuggestedLabel(
  PhotoEntry photo,
  String sectionName,
  InspectionMetadata metadata,
) async {
  // Extract image bytes so future integrations can send them to an AI service.
  List<int> bytes = [];
  try {
    if (await File(photo.url).exists()) {
      bytes = await File(photo.url).readAsBytes();
    }
  } catch (_) {
    // Ignore errors for now; bytes remain empty.
  }

  final String _base64 = base64Encode(bytes); // ignore: unused_local_variable

  await Future.delayed(const Duration(milliseconds: 300));
  final desc = _fakeDescriptions[Random().nextInt(_fakeDescriptions.length)];
  return '$desc ($sectionName)';
}

