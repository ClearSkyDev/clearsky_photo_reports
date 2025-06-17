import 'package:flutter/foundation.dart';
import 'checklist_template.dart';
import 'checklist_field_type.dart';
import '../utils/checklist_storage.dart';

class ChecklistStep {
  final String title;
  final ChecklistFieldType type;
  final int requiredPhotos;
  int photosTaken;
  bool isComplete;
  String textValue;
  String dropdownValue;
  bool toggleValue;
  final List<String> options;

  ChecklistStep({
    required this.title,
    this.type = ChecklistFieldType.toggle,
    this.requiredPhotos = 0,
    this.photosTaken = 0,
    this.isComplete = false,
    this.textValue = '',
    this.dropdownValue = '',
    this.toggleValue = false,
    this.options = const [],
  });
}

class InspectionChecklist extends ChangeNotifier {
  final List<ChecklistStep> steps = [];

  Future<void> loadSaved() async {
    await ChecklistStorage.load(this);
    notifyListeners();
  }

  void loadTemplate(ChecklistTemplate template) {
    steps
      ..clear()
      ..addAll(template.items.map(
        (e) => ChecklistStep(
          title: e.title,
          type: e.type,
          requiredPhotos: e.requiredPhotos,
          options: e.options,
        ),
      ));
    notifyListeners();
    ChecklistStorage.save(this);
  }

  void markComplete(String title) {
    for (final step in steps) {
      if (step.title == title && !step.isComplete) {
        step.isComplete = true;
        notifyListeners();
        ChecklistStorage.save(this);
        break;
      }
    }
  }

  void updateToggle(String title, bool value) {
    for (final step in steps) {
      if (step.title == title && step.type == ChecklistFieldType.toggle) {
        step.toggleValue = value;
        step.isComplete = value;
        notifyListeners();
        ChecklistStorage.save(this);
        break;
      }
    }
  }

  void updateText(String title, String value) {
    for (final step in steps) {
      if (step.title == title && step.type == ChecklistFieldType.text) {
        step.textValue = value;
        step.isComplete = value.isNotEmpty;
        notifyListeners();
        ChecklistStorage.save(this);
        break;
      }
    }
  }

  void updateDropdown(String title, String value) {
    for (final step in steps) {
      if (step.title == title && step.type == ChecklistFieldType.dropdown) {
        step.dropdownValue = value;
        step.isComplete = value.isNotEmpty;
        notifyListeners();
        ChecklistStorage.save(this);
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
        ChecklistStorage.save(this);
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
