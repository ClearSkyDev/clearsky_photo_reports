import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/saved_report.dart';
import '../models/inspection_metadata.dart';
import '../utils/export_utils.dart';
import 'client_signature_screen.dart';
import 'message_thread_screen.dart';

/// Displays a finalized report via the public share link.
class PublicReportScreen extends StatefulWidget {
  final String publicId;
  const PublicReportScreen({super.key, required this.publicId});

  @override
  State<PublicReportScreen> createState() => _PublicReportScreenState();
}

class _PublicReportScreenState extends State<PublicReportScreen> {
  late Future<SavedReport?> _futureReport;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureReport = _loadReport();
  }

  Future<SavedReport?> _loadReport() async {
    final query = await FirebaseFirestore.instance
        .collection('reports')
        .where('publicReportId', isEqualTo: widget.publicId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return SavedReport.fromMap(doc.data(), doc.id);
  }

  Future<void> _addComment(String reportId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .add({'text': text, 'createdAt': Timestamp.now()});
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Comment submitted')));
      }
      _commentController.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit comment')));
      }
    }
  }

  Widget _buildBody(SavedReport report, String reportId) {
    final meta = InspectionMetadata.fromMap(report.inspectionMetadata);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Roof Inspection Report',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(meta.propertyAddress),
          const SizedBox(height: 4),
          Text('Client: ${meta.clientName}'),
          const SizedBox(height: 12),
          if ((report.aiSummary?.status == 'approved' ||
                  report.aiSummary?.status == 'edited') &&
              report.summaryText != null &&
              report.summaryText!.isNotEmpty) ...[
            const Text('Summary of Findings',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(report.summaryText!),
            if (report.aiSummary?.editor != null)
              Text('Reviewed by ${report.aiSummary!.editor} on ${report.aiSummary!.editedAt?.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
          ],
          for (final struct in report.structures) ...[
            Text(struct.name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final entry in struct.sectionPhotos.entries) ...[
              Text(entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final photo in entry.value)
                    Image.network(photo.photoUrl, width: 120, height: 120,
                        fit: BoxFit.cover),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 16),
          if (report.signatureRequested && report.signatureStatus == 'pending')
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ClientSignatureScreen(reportId: reportId)),
                );
                if (result != null) {
                  setState(() {
                    _futureReport = _loadReport();
                  });
                }
              },
              child: const Text('Sign Report'),
            ),
          if (report.signatureStatus == 'signed' &&
              report.homeownerSignature != null) ...[
            const SizedBox(height: 8),
            Text('Signed by ${report.homeownerSignature!.name}'),
            const SizedBox(height: 4),
            Image.memory(
              base64Decode(report.homeownerSignature!.image),
              height: 80,
            ),
          ],
          if (report.signatureStatus == 'declined' &&
              report.homeownerSignature != null) ...[
            const SizedBox(height: 8),
            Text('Signature declined: ${report.homeownerSignature!.declineReason ?? ''}'),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final file = await exportFinalZip(report);
              if (file != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ZIP downloaded')));
              }
            },
            child: const Text('Download ZIP'),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _commentController,
            decoration:
                const InputDecoration(labelText: 'Leave a comment'),
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _addComment(reportId),
            child: const Text('Submit Comment'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MessageThreadScreen(reportId: reportId, threadTitle: '', currentUserId: '',),
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
      appBar: AppBar(title: const Text('Public Report')),
      body: FutureBuilder<SavedReport?>(
        future: _futureReport,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Report not found'));
          }
          return _buildBody(snapshot.data!, snapshot.data!.id);
        },
      ),
    );
  }
}

