import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../app/app_theme.dart';
import '../../../models/simple_inspection_metadata.dart';

/// Landing screen with project creation and upgrade prompts.
class HomeScreen extends StatelessWidget {
  final int freeReportsRemaining;
  final bool isSubscribed;

  const HomeScreen({
    super.key,
    required this.freeReportsRemaining,
    required this.isSubscribed,
  });

  void _handleCreateProject(BuildContext context) {
    Navigator.pushNamed(context, '/projectDetails');
  }

  void _handleUpgrade(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Upgrade Required'),
        content: const Text(
          'Please upgrade your account to continue using ClearSky.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _checkSubscription(BuildContext context) {
    if (freeReportsRemaining <= 0 && !isSubscribed) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Upgrade Needed'),
          content: const Text(
            'You have reached your free report limit. Upgrade to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _handleUpgrade(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Upgrade',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      _handleCreateProject(context);
    }
  }

  Future<List<InspectionMetadata>> _loadProjects() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('inspections')
        .get();

    final projects = snapshot.docs
        .map((doc) => InspectionMetadata.fromMap(doc.id, doc.data()))
        .toList();

    projects.sort((a, b) {
      if (a.appointmentDate == null && b.appointmentDate == null) return 0;
      if (a.appointmentDate == null) return 1;
      if (b.appointmentDate == null) return -1;
      return a.appointmentDate!.compareTo(b.appointmentDate!);
    });

    return projects;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.clearSkyTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ClearSky'),
        backgroundColor: AppTheme.clearSkyTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isSubscribed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.yellow.shade100,
              child: Text(
                'Free trial: $freeReportsRemaining report${freeReportsRemaining == 1 ? '' : 's'} remaining',
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'ClearSky Photo Reports',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text('Create professional inspection reports'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _checkSubscription(context),
            icon: const Icon(Icons.add),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.clearSkyBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0.5, 0.5),
                    blurRadius: 2,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
            label: const Text('Create Project'),
          ),
          Expanded(
            child: FutureBuilder(
              future: _loadProjects(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final projects = snapshot.data as List<InspectionMetadata>;

                if (projects.isEmpty) {
                  return const Center(child: Text('No inspections found'));
                }

                return ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final isUnscheduled = project.appointmentDate == null;

                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/projectDetails',
                        arguments: project,
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isUnscheduled
                                ? const Color(0xFF007BFF)
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.clientName,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('Project #: ${project.projectNumber}'),
                            Text('Claim #: ${project.claimNumber}'),
                            if (project.appointmentDate != null)
                              Text(
                                'Appt: ${DateFormat("MMM d, yyyy h:mm a").format(project.appointmentDate!)}',
                              ),
                            if (project.appointmentDate == null)
                              const Text(
                                'No Appointment Set',
                                style: TextStyle(
                                    color: Color(0xFF007BFF),
                                    fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (i) {
          switch (i) {
            case 1:
              Navigator.pushNamed(context, '/capture');
              break;
            case 2:
              Navigator.pushNamed(context, '/history');
              break;
            case 3:
              Navigator.pushNamed(context, '/settings');
              break;
            default:
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Camera'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
