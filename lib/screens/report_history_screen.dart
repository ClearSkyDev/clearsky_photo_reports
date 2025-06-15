import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/saved_report.dart';
import '../models/inspection_metadata.dart';
import '../models/photo_entry.dart';
import 'report_preview_screen.dart';

class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  late Future<List<SavedReport>> _futureReports;

  @override
  void initState() {
    super.initState();
    _futureReports = _loadReports();
  }

  Future<List<SavedReport>> _loadReports() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => SavedReport.fromMap(doc.data(), doc.id))
        .toList();
  }

  Widget _buildTile(SavedReport report) {
    final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
    String date = meta.inspectionDate.toLocal().toString().split(' ')[0];
    String subtitle = '${meta.clientName} • $date';
    String? thumbUrl;
    for (var photos in report.sectionPhotos.values) {
      if (photos.isNotEmpty) {
        thumbUrl = photos.first.photoUrl;
        break;
      }
    }
    return ListTile(
      leading: thumbUrl != null
          ? Image.network(thumbUrl!, width: 56, height: 56, fit: BoxFit.cover)
          : const Icon(Icons.description),
      title: Text(meta.propertyAddress),
      subtitle: Text(subtitle),
      onTap: () {
        final sections = <String, List<PhotoEntry>>{};
        report.sectionPhotos.forEach((key, value) {
          sections[key] =
              value.map((e) => PhotoEntry(url: e.photoUrl, label: e.label)).toList();
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportPreviewScreen(
              metadata: meta,
              sections: sections,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report History')),
      body: FutureBuilder<List<SavedReport>>(
        future: _futureReports,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading reports'));
          }
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return const Center(child: Text('No reports found'));
          }
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) => _buildTile(reports[index]),
          );
        },
      ),
    );
  }
}
