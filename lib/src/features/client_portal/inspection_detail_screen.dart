import 'package:flutter/material.dart';

import '../../core/models/inspection_report.dart';

class InspectionDetailScreen extends StatelessWidget {
  final InspectionReport report;

  const InspectionDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(report.title ?? 'Inspection Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${report.id}'),
            if (report.address != null) Text('Address: ${report.address}'),
            Text('Date: ${report.date.toLocal()}'),
            const SizedBox(height: 16),
            Text(report.synced ? 'Synced' : 'Not Synced'),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: report.photoPaths.length,
                itemBuilder: (context, index) {
                  final path = report.photoPaths[index];
                  return ListTile(
                    leading: const Icon(Icons.photo),
                    title: Text(path.split('/').last),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
