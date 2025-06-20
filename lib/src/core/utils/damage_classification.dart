import 'dart:math';

import '../models/photo_entry.dart';
import '../models/inspection_metadata.dart';

final List<String> _fakeDamageTypes = [
  'Hail Damage',
  'Wind Damage',
  'Wear & Tear',
  'No Damage Found',
];

/// Returns a simulated damage classification for [photo] in the given [sectionName].
///
/// [metadata] and [photo] bytes are accepted so this function can later send
/// them to an AI service. Currently a random damage type is returned.
Future<String> getDamageType(
  PhotoEntry photo,
  String sectionName,
  InspectionMetadata metadata,
) async {
  // Placeholder for future image byte extraction.

  await Future.delayed(const Duration(milliseconds: 300));
  return _fakeDamageTypes[Random().nextInt(_fakeDamageTypes.length)];
}
