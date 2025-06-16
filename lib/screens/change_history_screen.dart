import 'package:flutter/material.dart';

import '../models/saved_report.dart';
import '../models/report_change.dart';

class ChangeHistoryScreen extends StatelessWidget {
  final SavedReport report;
  const ChangeHistoryScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final changes = report.changeLog;
    return Scaffold(
      appBar: AppBar(title: const Text('Change History')),
      body: ListView.builder(
        itemCount: changes.length,
        itemBuilder: (context, index) {
          final ReportChange change = changes[index];
          return ListTile(
            title: Text(change.type),
            subtitle: Text(change.timestamp.toLocal().toString()),
          );
        },
      ),
    );
  }
}
