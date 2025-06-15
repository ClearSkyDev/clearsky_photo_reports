import 'package:flutter/material.dart';
import '../models/inspection_metadata.dart';

class SendReportScreen extends StatefulWidget {
  final InspectionMetadata metadata;
  const SendReportScreen({super.key, required this.metadata});

  @override
  State<SendReportScreen> createState() => _SendReportScreenState();
}

class _SendReportScreenState extends State<SendReportScreen> {
  final TextEditingController _emailController = TextEditingController();

  void _downloadPdf() {
    // TODO: reuse _downloadPdf from ReportPreviewScreen
  }

  void _downloadHtml() {
    // TODO: reuse _saveHtmlFile logic
  }

  Future<void> _sendEmail() async {
    if (_emailController.text.isEmpty) return;
    // TODO: call sendReportByEmail
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metadata;
    return Scaffold(
      appBar: AppBar(title: const Text('Send Report')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client: ${m.clientName}'),
                    Text('Address: ${m.propertyAddress}'),
                    Text('Date: ${m.inspectionDate.toLocal().toString().split(' ')[0]}'),
                  ],
                ),
              ),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Client Email'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _downloadPdf, child: const Text('Download PDF')),
                ElevatedButton(onPressed: _downloadHtml, child: const Text('Download HTML')),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _emailController.text.isEmpty ? null : _sendEmail,
              child: const Text('Send via Email'),
            ),
          ],
        ),
      ),
    );
  }
}
