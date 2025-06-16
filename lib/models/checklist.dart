import 'package:flutter/foundation.dart';
import 'checklist_template.dart';

class ChecklistStep {
  final String title;
  final int requiredPhotos;
  int photosTaken;
  bool isComplete;

  ChecklistStep({
    required this.title,
    this.requiredPhotos = 0,
    this.photosTaken = 0,
    this.isComplete = false,
  });
}

class InspectionChecklist extends ChangeNotifier {
  final List<ChecklistStep> steps = [];

  void loadTemplate(ChecklistTemplate template) {
    steps
      ..clear()
      ..addAll(template.items
          .map((e) => ChecklistStep(title: e.title, requiredPhotos: e.requiredPhotos)));
    notifyListeners();
  }

  void markComplete(String title) {
    for (final step in steps) {
      if (step.title == title && !step.isComplete) {
        step.isComplete = true;
        notifyListeners();
        break;
      }
    }
  }

  void recordPhoto(String title) {
    for (final step in steps) {
      if (step.title == title) {
        step.photosTaken++;
        if (!step.isComplete && step.photosTaken >= step.requiredPhotos && step.requiredPhotos > 0) {
          step.isComplete = true;
        }
        notifyListeners();
        break;
      }
    }
  }

  int get completed => steps.where((s) => s.isComplete).length;
  double get progress => steps.isEmpty ? 0 : completed / steps.length;
  bool get allComplete => completed == steps.length;

  bool get allRequiredComplete {
    for (final step in steps) {
      if (step.requiredPhotos > 0 && step.photosTaken < step.requiredPhotos) {
        return false;
      }
      if (step.requiredPhotos == 0 && !step.isComplete) {
        return false;
      }
    }
    return true;
  }
}

final InspectionChecklist inspectionChecklist = InspectionChecklist();
