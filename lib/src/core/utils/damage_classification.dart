import 'dart:math';
import 'dart:io';
import 'dart:convert';

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
  // Extract image bytes for future AI integrations.
  List<int> bytes = [];
  try {
    if (await File(photo.url).exists()) {
      bytes = await File(photo.url).readAsBytes();
    }
  } catch (_) {}

  final base64 = base64Encode(bytes); // ignore: unused_local_variable

  await Future.delayed(const Duration(milliseconds: 300));
  return _fakeDamageTypes[Random().nextInt(_fakeDamageTypes.length)];
}
