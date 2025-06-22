import 'package:flutter/material.dart';
import '../../core/utils/export_utils.dart' as export_utils;
import '../../core/services/subscription_service.dart';
import '../../core/models/inspection_metadata.dart';
import '../../core/models/photo_entry.dart';
import '../../core/services/inspector_role_service.dart';

/// Displays a simple preview of the finalized report and provides
/// buttons to export the results or email them to a client.
class FinalReportReviewScreen extends StatelessWidget {
  final List<PhotoEntry> uploadedPhotos;
  final InspectionMetadata metadata;
  final InspectorRole role;
  final List<String> externalReportUrls;
  final String summaryText;
  final String signatureData;

  const FinalReportReviewScreen({
    super.key,
    required this.uploadedPhotos,
    required this.metadata,
    required this.role,
    required this.externalReportUrls,
    required this.summaryText,
    required this.signatureData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Final Report Preview')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Client: ${metadata.clientName}',
              style: const TextStyle(fontSize: 18)),
          Text('Address: ${metadata.propertyAddress}'),
          if (metadata.insuranceCarrier != null)
            Text('Carrier: ${metadata.insuranceCarrier}'),
          const SizedBox(height: 16),
          const Divider(),
          const Text('Photo Sections',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ..._renderSections(),
          const SizedBox(height: 16),
          if (externalReportUrls.isNotEmpty) ...[
            const Divider(),
            const Text('Attached Reports',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...externalReportUrls.map((url) => Text(url.split('/').last)),
          ],
          const Divider(),
          const Text('Inspector Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(summaryText, style: const TextStyle(fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          if (signatureData.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Inspector Signature'),
                Image.memory(
                  Uri.parse(signatureData).data!.contentAsBytes(),
                  height: 100,
                ),
              ],
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export as PDF'),
            onPressed: () async {
              final pro = await SubscriptionService.isPro();
              if (!context.mounted) return;
              if (!pro) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Pro Feature'),
                    content: const Text('Upgrade to export PDF reports.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }

              await export_utils.generateAndDownloadPdf(
                uploadedPhotos,
                summaryText,
              );
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.web),
            label: const Text('Export as HTML'),
            onPressed: () async {
              final pro = await SubscriptionService.isPro();
              if (!context.mounted) return;
              if (!pro) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Pro Feature'),
                    content: const Text('Upgrade to export HTML reports.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }

              await export_utils.generateAndDownloadHtml(
                uploadedPhotos,
                summaryText,
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _renderSections() {
    final sections = uploadedPhotos.map((p) => p.label).toSet().toList();
    return sections.map((section) {
      final photos = uploadedPhotos.where((p) => p.label == section).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section, style: const TextStyle(fontWeight: FontWeight.bold)),
          ...photos.map((photo) => Column(
                children: [
                  Image.network(photo.url, height: 150),
                  Text(photo.caption.isNotEmpty ? photo.caption : photo.label),
                  const SizedBox(height: 12),
                ],
              )),
          const SizedBox(height: 12),
        ],
      );
    }).toList();
  }
}
