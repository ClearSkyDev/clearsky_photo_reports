import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ClientDashboardScreen extends StatelessWidget {
  const ClientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Dashboard'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to the Client Dashboard!',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  final ref = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('inspections')
                      .add({
                    'createdAt': Timestamp.now(),
                    'status': 'draft',
                    'photos': [],
                  });

                  if (!context.mounted) return;
                  Navigator.pushNamed(
                    context,
                    '/capture',
                    arguments: {'inspectionId': ref.id},
                  );
                },
                child: const Text('Start Inspection'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/history');
                },
                child: const Text('View Inspections'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
