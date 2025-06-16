import 'package:flutter/material.dart';
import '../models/checklist.dart';

class InspectionChecklistScreen extends StatefulWidget {
  const InspectionChecklistScreen({super.key});

  @override
  State<InspectionChecklistScreen> createState() => _InspectionChecklistScreenState();
}

class _InspectionChecklistScreenState extends State<InspectionChecklistScreen> {
  @override
  void initState() {
    super.initState();
    inspectionChecklist.addListener(_update);
  }

  @override
  void dispose() {
    inspectionChecklist.removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final steps = inspectionChecklist.steps;
    return Scaffold(
      appBar: AppBar(title: const Text('Inspection Checklist')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LinearProgressIndicator(value: inspectionChecklist.progress),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: steps.length,
              itemBuilder: (_, i) {
                final step = steps[i];
                return ListTile(
                  leading: Icon(
                    step.isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: step.isComplete ? Colors.green : Colors.grey,
                  ),
                  title: Text(step.title),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
