import 'package:flutter/material.dart';

import '../../core/services/changelog_service.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = ChangelogService.instance.entries;
    return Scaffold(
      appBar: AppBar(title: const Text("What's New")),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final e = entries[index];
          return ExpansionTile(
            title: Text(
                '${e.version} - ${e.date.toLocal().toString().split(' ')[0]}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final h in e.highlights)
                      Row(
                        children: [
                          const Icon(Icons.circle, size: 6),
                          const SizedBox(width: 6),
                          Expanded(child: Text(h)),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Text(e.notes),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
