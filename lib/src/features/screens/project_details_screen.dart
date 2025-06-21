import 'package:flutter/material.dart';

/// Simple screen to capture project details. Replace with full form later.
class ProjectDetailsScreen extends StatelessWidget {
  const ProjectDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Project Details')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Form fields for inspection metadata here...'),
      ),
    );
  }
}
