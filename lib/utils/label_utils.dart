import '../models/checklist_template.dart';

/// Format [damageType] for display based on the inspector [role].
///
/// Adjusters see the raw damage type label. Contractors and
/// third-party inspectors see "Evidence of <Type> Damage". The word
/// "Damage" is never shown alone.
String formatDamageLabel(String damageType, Set<InspectorReportRole> roles) {
  if (damageType.isEmpty || damageType == 'Unknown') return '';
  if (roles.contains(InspectorReportRole.adjuster)) {
    return damageType;
  }
  var base = damageType
      .replaceAll(RegExp('evidence of', caseSensitive: false), '')
      .replaceAll(RegExp('damage', caseSensitive: false), '')
      .trim();
  if (base.isEmpty) {
    return 'Evidence of Damage';
  }
  base = base[0].toUpperCase() + base.substring(1);
  return 'Evidence of $base Damage';
}
