import 'package:flutter/material.dart';
import '../../core/models/checklist.dart';
import '../../core/models/checklist_field_type.dart';
import '../../core/utils/checklist_storage.dart';

class InspectionChecklistScreen extends StatefulWidget {
  const InspectionChecklistScreen({super.key});

  @override
  State<InspectionChecklistScreen> createState() =>
      _InspectionChecklistScreenState();
}

class _InspectionChecklistScreenState extends State<InspectionChecklistScreen> {
  final Map<String, TextEditingController> _controllers = {};
  @override
  void initState() {
    super.initState();
    for (final step in inspectionChecklist.steps) {
      if (step.type == ChecklistFieldType.text) {
        _controllers[step.title] =
            TextEditingController(text: step.textValue);
      }
    }
    inspectionChecklist.addListener(_update);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    inspectionChecklist.removeListener(_update);
    super.dispose();
  }

  void _update() {
    for (final step in inspectionChecklist.steps) {
      if (step.type == ChecklistFieldType.text &&
          !_controllers.containsKey(step.title)) {
        _controllers[step.title] =
            TextEditingController(text: step.textValue);
      }
    }
    setState(() {});
  }

  void _showAddStepDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Step'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final text = titleController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  inspectionChecklist.steps.add(
                    ChecklistStep(title: text),
                  );
                  _controllers[text] = TextEditingController();
                  ChecklistStorage.save(inspectionChecklist);
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

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
                final subtitle = step.requiredPhotos > 0
                    ? '${step.photosTaken}/${step.requiredPhotos} photos'
                    : null;
                Widget tile;
                switch (step.type) {
                  case ChecklistFieldType.text:
                    final controller = _controllers[step.title] ??=
                        TextEditingController(text: step.textValue);
                    tile = ListTile(
                      title: Text(step.title),
                      subtitle: TextField(
                        controller: controller,
                        onChanged: (v) =>
                            inspectionChecklist.updateText(step.title, v),
                      ),
                    );
                    break;
                  case ChecklistFieldType.dropdown:
                    tile = ListTile(
                      title: Text(step.title),
                      subtitle: DropdownButton<String>(
                        value: step.dropdownValue.isEmpty
                            ? null
                            : step.dropdownValue,
                        hint: const Text('Select'),
                        items: step.options
                            .map((o) => DropdownMenuItem(
                                  value: o,
                                  child: Text(o),
                                ))
                            .toList(),
                        onChanged: (val) => val != null
                            ? inspectionChecklist.updateDropdown(
                                step.title, val)
                            : null,
                      ),
                    );
                    break;
                  case ChecklistFieldType.photo:
                    tile = CheckboxListTile(
                      value: step.isComplete,
                      onChanged: (_) {},
                      title: Text(step.title),
                      subtitle: subtitle != null ? Text(subtitle) : null,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                    break;
                  default:
                    tile = SwitchListTile(
                      value: step.toggleValue,
                      onChanged: (val) =>
                          inspectionChecklist.updateToggle(step.title, val),
                      title: Text(step.title),
                    );
                }
                return tile;
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStepDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
