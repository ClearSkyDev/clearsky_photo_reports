/// Utilities for generating AI-based label suggestions.
///
/// Currently provides a placeholder [getLabelSuggestion] function that returns a
/// fake label for a photo. In the future this will call an AI service such as
/// OpenAI or a custom model.
library;

import 'dart:math';

import '../models/photo_entry.dart';
import '../models/inspection_metadata.dart';
import '../models/label_suggestion.dart';

final List<String> _fakeDescriptions = [
  'Hail impact near ridge',
  'Wind crease on shingle',
  'Loose flashing',
  'Missing fasteners',
  'Potential leak area',
];

/// Returns a fake suggested [LabelSuggestion] for [photo] in the given
/// [sectionName].
///
/// [metadata] provides additional context about the inspection that may be
/// leveraged by future AI models. Currently a random description and confidence
/// score are returned after a short delay.
Future<LabelSuggestion> getLabelSuggestion(
  PhotoEntry photo,
  String sectionName,
  InspectionMetadata metadata,
) async {
  // Placeholder for future image byte extraction.

  await Future.delayed(const Duration(milliseconds: 300));
  final desc = _fakeDescriptions[Random().nextInt(_fakeDescriptions.length)];
  final confidence = Random().nextDouble() * 0.4 + 0.6; // 0.6 - 1.0
  return LabelSuggestion(
    label: desc,
    caption: 'Detected in $sectionName',
    confidence: double.parse(confidence.toStringAsFixed(2)),
    reason: 'Placeholder AI analysis',
  );
}
