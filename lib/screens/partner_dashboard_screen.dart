import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/saved_report.dart';

class PartnerDashboardScreen extends StatelessWidget {
  final String partnerId;
  const PartnerDashboardScreen({super.key, required this.partnerId});

  Stream<List<SavedReport>> _reports() {
    return FirebaseFirestore.instance
        .collection('reports')
        .where('partnerId', isEqualTo: partnerId)
        .snapshots()
        .map((s) => s.docs
            .map((d) => SavedReport.fromMap(d.data(), d.id))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Referral Dashboard')),
      body: StreamBuilder<List<SavedReport>>(
        stream: _reports(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = snapshot.data!;
          final completed =
              reports.where((r) => r.isFinalized).toList().length;
          final avgTurnaround = reports
              .where((r) => r.isFinalized)
              .map((r) => r.lastEditedAt!.difference(r.createdAt).inHours)
              .fold<int>(0, (a, b) => a + b);
          final avg = completed > 0 ? avgTurnaround / completed : 0;
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Total Referrals: ${reports.length}'),
                Text('Completion Rate: ${reports.isEmpty ? 0 : (completed / reports.length * 100).toStringAsFixed(1)}%'),
                Text('Avg Turnaround: ${avg.toStringAsFixed(1)} hrs'),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: reports.map((r) {
                      final meta = r.inspectionMetadata;
                      final status = r.isFinalized ? 'finalized' : 'draft';
                      return ListTile(
                        title: Text(meta['propertyAddress'] ?? ''),
                        subtitle: Text(status),
                        onTap: () {
                          if (r.publicViewLink != null) {
                            Navigator.pushNamed(context, r.publicViewLink!);
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
