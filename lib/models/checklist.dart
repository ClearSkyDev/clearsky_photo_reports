import 'package:flutter/foundation.dart';

class ChecklistStep {
  final String title;
  bool isComplete;

  ChecklistStep({required this.title, this.isComplete = false});
}

class InspectionChecklist extends ChangeNotifier {
  final List<ChecklistStep> steps = [
    ChecklistStep(title: 'Address Photo'),
    ChecklistStep(title: 'Elevation Photos'),
    ChecklistStep(title: 'Metadata Saved'),
    ChecklistStep(title: 'Signature Captured'),
    ChecklistStep(title: 'Report Previewed'),
    ChecklistStep(title: 'Report Exported'),
  ];

  void markComplete(String title) {
    for (final step in steps) {
      if (step.title == title && !step.isComplete) {
        step.isComplete = true;
        notifyListeners();
        break;
      }
    }
  }

  int get completed => steps.where((s) => s.isComplete).length;
  double get progress => steps.isEmpty ? 0 : completed / steps.length;
  bool get allComplete => completed == steps.length;
}

final InspectionChecklist inspectionChecklist = InspectionChecklist();
