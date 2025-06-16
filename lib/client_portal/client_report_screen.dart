import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/saved_report.dart';
import '../models/inspection_metadata.dart';
import '../utils/export_utils.dart';
import '../screens/message_thread_screen.dart';
import '../services/client_activity_service.dart';
import 'package:printing/printing.dart';

class ClientReportScreen extends StatefulWidget {
  final String reportId;
  const ClientReportScreen({super.key, required this.reportId});

  @override
  State<ClientReportScreen> createState() => _ClientReportScreenState();
}

class _ClientReportScreenState extends State<ClientReportScreen> {
  late Future<SavedReport?> _futureReport;
  @override
  void initState() {
    super.initState();
    _futureReport = _load();
  }

  Future<SavedReport?> _load() async {
    final doc = await FirebaseFirestore.instance.collection('reports').doc(widget.reportId).get();
    if (!doc.exists) return null;
    return SavedReport.fromMap(doc.data()!, doc.id);
  }

  Widget _buildBody(SavedReport report) {
    final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Roof Inspection Report', style: Theme.of(context).textTheme.headline6),
          const SizedBox(height: 8),
          Text(meta.propertyAddress),
          const SizedBox(height: 4),
          Text('Client: ${meta.clientName}'),
          const SizedBox(height: 12),
          if (report.summaryText != null && report.summaryText!.isNotEmpty) ...[
            const Text('Summary of Findings', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(report.summaryText!),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: () async {
              await ClientActivityService().log('view_pdf', reportId: report.id);
              final pdf = await generatePdf(report);
              await Printing.layoutPdf(onLayout: (_) => pdf);
            },
            child: const Text('View PDF'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              await ClientActivityService().log('download_zip', reportId: report.id);
              await exportFinalZip(report);
            },
            child: const Text('Download ZIP'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessageThreadScreen(reportId: report.id),
                ),
              );
            },
            child: const Text('Open Messages'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report')),
      body: FutureBuilder<SavedReport?>(
        future: _futureReport,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return const Center(child: Text('Report not found'));
          }
          return _buildBody(snapshot.data!);
        },
      ),
    );
  }
}
