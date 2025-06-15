/// Utilities for generating AI-based label suggestions.
///
/// Currently provides a placeholder [getSuggestedLabel] function that returns a
/// fake label for a photo. In the future this will call an AI service such as
/// OpenAI or a custom model.

import 'dart:math';

import '../models/photo_entry.dart';

final List<String> _fakeDescriptions = [
  'Hail impact near ridge',
  'Wind crease on shingle',
  'Loose flashing',
  'Missing fasteners',
  'Potential leak area',
];

/// Returns a fake suggested label for [photo] in the given [sectionName].
Future<String> getSuggestedLabel(PhotoEntry photo, String sectionName) async {
  await Future.delayed(const Duration(milliseconds: 300));
  final desc = _fakeDescriptions[Random().nextInt(_fakeDescriptions.length)];
  return '$desc ($sectionName)';
}

