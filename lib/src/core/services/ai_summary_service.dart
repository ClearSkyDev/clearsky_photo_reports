import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/saved_report.dart';
import '../models/inspector_report_role.dart';

class AiSummary {
  final String adjuster;
  final String homeowner;

  AiSummary({required this.adjuster, required this.homeowner});
}

class AiSummaryService {
  final String apiKey;
  final String apiUrl;

  AiSummaryService(
      {required this.apiKey,
      this.apiUrl = 'https://api.openai.com/v1/chat/completions'});

  Future<AiSummary> generateSummary(SavedReport report) async {
    final sectionData = <Map<String, dynamic>>[];
    for (final struct in report.structures) {
      for (final entry in struct.sectionPhotos.entries) {
        if (entry.value.isEmpty) continue;
        final photos = entry.value
            .map((p) => {
                  'label': p.label,
                  'damage': p.damageType,
                  'note': p.note,
                })
            .toList();
        sectionData.add({
          'structure': struct.name,
          'section': entry.key,
          'photos': photos,
        });
      }
    }

    final roleList = (report.inspectionMetadata['inspectorRoles'] as List?) ??
        ['ladderAssist'];
    final roles = roleList
        .map((e) => InspectorReportRole.values.byName(e as String))
        .toSet();

    String prompt;

    String ladderAssistText =
        'You are a third-party roof inspector. Your job is to document findings only.\n'
        'Do not mention recommendations, causes, or coverage.';
    String adjusterText =
        'You are an insurance adjuster. Discuss whether observed damage is consistent with covered perils and how it may impact claim decisions.';
    String contractorText =
        'You are a roofing contractor. Offer repair or replacement suggestions where appropriate.';

    if (roles.length == 1) {
      if (roles.contains(InspectorReportRole.ladderAssist)) {
        prompt = '$ladderAssistText\n\nHere are the findings: ${jsonEncode(sectionData)}';
      } else if (roles.contains(InspectorReportRole.adjuster)) {
        prompt = '$adjusterText\n\nFindings: ${jsonEncode(sectionData)}';
      } else {
        prompt = '$contractorText\n\nInspection Results: ${jsonEncode(sectionData)}';
      }
    } else {
      final parts = <String>[];
      if (roles.contains(InspectorReportRole.ladderAssist)) {
        parts.add('While this is a third-party inspection, provide objective documentation.');
      }
      if (roles.contains(InspectorReportRole.adjuster)) {
        parts.add('Explain how the findings may assist in claim resolution.');
      }
      if (roles.contains(InspectorReportRole.contractor)) {
        parts.add('Include practical repair or replacement suggestions.');
      }
      prompt = '${parts.join(' ')}\n\nFindings: ${jsonEncode(sectionData)}';
    }

    final messages = [
      {'role': 'system', 'content': 'You summarize roof inspection findings.'},
      {'role': 'user', 'content': prompt}
    ];

    final res = await http.post(Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': messages,
          'max_tokens': 300,
        }));

    if (res.statusCode != 200) {
      throw Exception('Failed to generate summary (${res.statusCode})');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>? ?? [];
    final content =
        choices.isNotEmpty ? choices.first['message']['content'] as String : '';

    final summary = content.trim();

    return AiSummary(adjuster: summary, homeowner: summary);
  }
}
