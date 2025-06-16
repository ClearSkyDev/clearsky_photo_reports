import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/saved_report.dart';

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

    final messages = [
      {
        'role': 'system',
        'content': 'You summarize roof inspection findings.'
      },
      {
        'role': 'user',
        'content':
            'Create two short paragraphs summarizing these inspection findings. '
                'First, a technical version for an insurance adjuster. Second, '
                'a simple version for the homeowner. Use the provided sections, labels, notes and damage tags. '
                'Data:\n${jsonEncode(sectionData)}'
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
    final parts = content.split(RegExp(r'\n\n+'));
    final adjuster = parts.isNotEmpty ? parts.first.trim() : '';
    final homeowner = parts.length > 1 ? parts[1].trim() : '';

    return AiSummary(adjuster: adjuster, homeowner: homeowner);
  }
}
