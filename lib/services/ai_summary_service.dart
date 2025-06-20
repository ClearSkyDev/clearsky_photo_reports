import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/saved_report.dart';
import '../models/checklist_template.dart' show InspectorReportRole;

class AiSummary {
  final String adjuster;
  final String homeowner;

  AiSummary({required this.adjuster, required this.homeowner});
}

class AiSummaryService {
  final String apiKey;
  final String apiUrl;

  AiSummaryService({required this.apiKey, this.apiUrl = 'https://api.openai.com/v1/chat/completions'});

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

    final roleList =
        (report.inspectionMetadata['inspectorRoles'] as List?) ?? ['ladderAssist'];
    final roles = roleList
        .map((e) => InspectorReportRole.values.byName(e as String))
        .toSet();

    String prompt;
    if (roles.contains(InspectorReportRole.ladderAssist) && roles.length == 1) {
      prompt =
          'You are a third-party roof inspector. Your job is to document findings only.\n'
          'Do not mention recommendations, causes, or coverage.\n'
          'Simply describe the condition and any observable damage.\n\n'
          'Here are the findings: ${jsonEncode(sectionData)}';
    } else if (roles.contains(InspectorReportRole.adjuster) && roles.length == 1) {
      prompt =
          'You are an insurance adjuster. Based on the observed damage and inspection findings, '
          'summarize the condition and note whether the damage is consistent with covered perils (like hail/wind).\n'
          'Lean into claim decision logic, but remain factual.\n\n'
          'Findings: ${jsonEncode(sectionData)}';
    } else if (roles.contains(InspectorReportRole.contractor) && roles.length == 1) {
      prompt =
          'You are a roofing contractor writing a report for a homeowner or claims submission.\n'
          'Use your summary to justify why repair or replacement may be needed based on the damage observed.\n\n'
          'Be persuasive but factual.\n\n'
          'Inspection Results: ${jsonEncode(sectionData)}';
    } else {
      prompt = 'Summarize these findings: ${jsonEncode(sectionData)}';
    }

    final messages = [
      {
        'role': 'system',
        'content': 'You summarize roof inspection findings.'
      },
      {
        'role': 'user',
        'content': prompt
      }
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
