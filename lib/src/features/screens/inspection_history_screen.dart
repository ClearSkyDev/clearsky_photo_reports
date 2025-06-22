import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../screens/inspection_report.dart';

/// Lists inspections for the current user and allows resuming photo capture.
class InspectionHistoryScreen extends StatelessWidget {
  const InspectionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('inspections')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Inspection History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final inspections = snapshot.data!.docs;
          if (inspections.isEmpty) {
            return const Center(child: Text('No inspections found'));
          }
          return ListView.builder(
            itemCount: inspections.length,
            itemBuilder: (_, i) {
              final data =
                  inspections[i].data() as Map<String, dynamic>? ?? {};
              final status = data['status'] ?? 'draft';
              final created = data['createdAt'];
              String date = '';
              if (created is Timestamp) {
                date = created.toDate().toLocal().toString().split(' ')[0];
              }
              return ListTile(
                title: Text(data['clientName'] ?? 'Unnamed'),
                subtitle: Text(
                  [data['address'], date].where((e) => e != null && e != '').join(' • '),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InspectionReportScreen(
                        inspectionId: inspections[i].id,
                      ),
                    ),
                  );
                },
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/capture',
                      arguments: {'inspectionId': inspections[i].id},
                    );
                  },
                  child: Text(status == 'complete' ? 'View' : 'Resume'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
