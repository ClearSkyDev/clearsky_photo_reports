import '../models/saved_report.dart';
import '../models/inspection_metadata.dart';

/// Generate a short paragraph summarizing the inspection results.
String generateSummaryText(SavedReport report) {
  final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
  final buffer = StringBuffer();
  final date = meta.inspectionDate.toLocal().toString().split(' ')[0];
  final inspector = meta.inspectorName ?? 'The inspector';

  buffer.write('On $date, $inspector inspected the property at ');
  buffer.write('${meta.propertyAddress} for ${meta.clientName}. ');

  if (report.structures.isNotEmpty) {
    final names = report.structures
        .map((s) => s.address?.isNotEmpty == true ? s.address! : s.name)
        .join(', ');
    buffer.write('Properties inspected included $names. ');
  }

  final sections = <String>{};
  final damages = <String>{};
  for (final struct in report.structures) {
    for (final entry in struct.sectionPhotos.entries) {
      if (entry.value.isNotEmpty) sections.add(entry.key);
      for (final photo in entry.value) {
        if (photo.damageType.isNotEmpty) damages.add(photo.damageType);
      }
    }
  }
  if (sections.isNotEmpty) {
    buffer.write('Photos were taken of ${_listSentence(sections)}. ');
  }
  if (damages.isNotEmpty) {
    buffer.write('Observed damage types include ${_listSentence(damages)}.');
  } else {
    buffer.write('No significant damages were noted.');
  }

  return buffer.toString();
}

String _listSentence(Iterable<String> items) {
  final list = items.toList();
  if (list.isEmpty) return '';
  if (list.length == 1) return list.first;
  final last = list.removeLast();
  return '${list.join(', ')} and $last';
}

/// Generate short summaries for each inspection section based on the
/// photos collected. The returned map is keyed by "Structure - Section" and
/// the value is a single paragraph describing that section.
Map<String, String> generateSectionSummaries(SavedReport report) {
  final summaries = <String, String>{};
  for (final struct in report.structures) {
    for (final entry in struct.sectionPhotos.entries) {
      final photos = entry.value;
      if (photos.isEmpty) continue;
      final damages = <String>{};
      for (final photo in photos) {
        if (photo.damageType.isNotEmpty && photo.damageType != 'Unknown') {
          damages.add(photo.damageType);
        }
      }
      final damageText = damages.isNotEmpty
          ? 'Damage types observed: ${_listSentence(damages)}.'
          : 'No notable damage found.';
      final key = '${struct.name} - ${entry.key}';
      summaries[key] = '${photos.length} photos collected. $damageText';
    }
    for (final room in struct.interiorRooms) {
      final photos = room.photos;
      if (photos.isEmpty) continue;
      final damages = <String>{};
      for (final photo in photos) {
        if (photo.damageType.isNotEmpty && photo.damageType != 'Unknown') {
          damages.add(photo.damageType);
        }
      }
      final damageText = damages.isNotEmpty
          ? 'Damage types observed: ${_listSentence(damages)}.'
          : 'No notable damage found.';
      final key = '${struct.name} - Interior - ${room.name}';
      summaries[key] = '${photos.length} photos collected. $damageText';
    }
  }
  return summaries;
}
