import 'package:flutter/material.dart';

class InspectionReportScreen extends StatelessWidget {
  const InspectionReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Report'),
      ),
      body: const Center(
        child: Text('Inspection Report Screen'),
      ),
    );
  }
}

/// Convenience function returning the [InspectionReportScreen] widget.
Widget inspectionReport() => const InspectionReportScreen();
