import '../models/checklist_template.dart';

/// Format [damageType] for display based on the inspector [role].
///
/// Adjusters see the raw damage type label. Contractors and
/// third-party inspectors see "Evidence of <Type> Damage". The word
/// "Damage" is never shown alone.
String formatDamageLabel(String damageType, InspectorReportRole role) {
  if (damageType.isEmpty || damageType == 'Unknown') return '';
  if (role == InspectorReportRole.adjuster) {
    return damageType;
  }
  var base = damageType
      .replaceAll(RegExp('(?i)evidence of'), '')
      .replaceAll(RegExp('(?i)damage'), '')
      .trim();
  if (base.isEmpty) {
    return 'Evidence of Damage';
  }
  base = base[0].toUpperCase() + base.substring(1);
  return 'Evidence of $base Damage';
}
