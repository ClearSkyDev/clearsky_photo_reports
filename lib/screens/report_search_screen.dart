import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/saved_report.dart';
import '../models/inspection_metadata.dart';
import '../models/inspected_structure.dart';
import '../models/photo_entry.dart';
import 'report_preview_screen.dart';

class ReportSearchScreen extends StatefulWidget {
  const ReportSearchScreen({super.key});

  @override
  State<ReportSearchScreen> createState() => _ReportSearchScreenState();
}

class _ReportSearchScreenState extends State<ReportSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<SavedReport> _results = [];
  bool _loading = false;

  Future<void> _search() async {
    final q = _controller.text.toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);
    final snap = await FirebaseFirestore.instance.collection('reports').get();
    final all =
        snap.docs.map((d) => SavedReport.fromMap(d.data(), d.id)).toList();
    final filtered = all.where((r) {
      final idx = r.searchIndex ?? {};
      bool match = false;
      if ((idx['address_lc'] ?? '').contains(q)) match = true;
      if (!match && (idx['clientName_lc'] ?? '').contains(q)) match = true;
      if (!match && (idx['inspectorName_lc'] ?? '').contains(q)) match = true;
      if (!match && (idx['type_lc'] ?? '').contains(q)) match = true;
      if (!match &&
          (idx['labels_lc'] as List<dynamic>? ?? [])
              .any((e) => (e as String).contains(q))) match = true;
      if (!match &&
          (idx['damageTags_lc'] as List<dynamic>? ?? [])
              .any((e) => (e as String).contains(q))) match = true;
      return match;
    }).toList();
    setState(() {
      _loading = false;
      _results = filtered;
    });
  }

  Widget _highlight(String text, String query) {
    final lc = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int index = text.toLowerCase().indexOf(lc);
    if (index < 0) return Text(text);
    while (index >= 0) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(backgroundColor: Colors.yellow)));
      start = index + query.length;
      index = text.toLowerCase().indexOf(lc, start);
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return RichText(
        text: TextSpan(style: const TextStyle(color: Colors.black), children: spans));
  }

  Widget _buildTile(SavedReport report) {
    final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
    final q = _controller.text;
    final structs = <InspectedStructure>[];
    for (var s in report.structures) {
      final sections = <String, List<PhotoEntry>>{};
      s.sectionPhotos.forEach((key, value) {
        sections[key] = value
            .map((e) => PhotoEntry(
                  url: e.photoUrl,
                  label: e.label,
                  damageType: e.damageType,
                  timestamp: e.timestamp ?? DateTime.now(),
                  latitude: e.latitude,
                  longitude: e.longitude,
                  note: e.note,
                ))
            .toList();
      });
      structs.add(InspectedStructure(name: s.name, sectionPhotos: sections));
    }
    return ListTile(
      title: _highlight(meta.propertyAddress, q),
      subtitle: _highlight(meta.clientName, q),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportPreviewScreen(
              metadata: meta,
              structures: structs,
              summary: report.summary,
              savedReport: report,
              readOnly: true,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Reports')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search reports',
                prefixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) => _buildTile(_results[index]),
            ),
          )
        ],
      ),
    );
  }
}
