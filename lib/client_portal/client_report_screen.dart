import 'package:flutter/material.dart';
import '../models/photo_entry.dart';
import '../utils/export_utils.dart'; // Your export functions
import '../widgets/clearsky_header.dart'; // Optional: logo + title widget

class ClientReportScreen extends StatelessWidget {
  final String clientName;
  final String propertyAddress;
  final List<PhotoEntry> photos;
  final String summaryText;
  final List<String> attachments; // file paths or URLs

  const ClientReportScreen({
    super.key,
    required this.clientName,
    required this.propertyAddress,
    required this.photos,
    required this.summaryText,
    this.attachments = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              await generateAndDownloadPdf(photos, summaryText);
            },
            tooltip: 'Download PDF',
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () async {
              await generateAndDownloadHtml(photos, summaryText);
            },
            tooltip: 'Download HTML',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ClearSkyHeader(), // Optional: your branded widget
            const SizedBox(height: 12),
            Text(
              'Client: $clientName\nAddress: $propertyAddress',
              style: Theme.of(context).textTheme.subtitle1,
            ),
            const SizedBox(height: 24),
            const Text(
              'Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(summaryText, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Text(
              'Photos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final photo = photos[index];
                return Column(
                  children: [
                    Expanded(
                      child: Image.network(photo.url, fit: BoxFit.cover),
                    ),
                    Text(
                      photo.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            if (attachments.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Supporting Documents',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  for (final file in attachments)
                    ListTile(
                      leading: const Icon(Icons.attachment),
                      title: Text(file.split('/').last),
                      onTap: () {
                        // Open link or viewer
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
