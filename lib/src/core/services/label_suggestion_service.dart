class LabelSuggestionService {
  static Future<String> suggestLabel({
    required String sectionPrefix,
    required String photoUri,
  }) async {
    // Simulated logic — replace with real ML later
    final lower = sectionPrefix.toLowerCase();
    if (lower.contains('front') && lower.contains('elevation')) {
      return 'Front elevation — downspout — possible hail';
    }
    if (lower.contains('roof') && lower.contains('slope')) {
      return 'Roof slope — shingle displacement — check for hail';
    }
    if (lower.contains('accessories')) {
      return 'Skylight — flashing damage suspected';
    }

    return '$sectionPrefix — needs review';
  }
}
