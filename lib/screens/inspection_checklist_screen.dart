import 'package:flutter/material.dart';
import '../models/checklist.dart';
import '../models/checklist_field_type.dart';
import '../utils/checklist_storage.dart';

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
                    tile = ListTile(
                      title: Text(step.title),
                      subtitle: TextField(
                        controller: TextEditingController(text: step.textValue),
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
                            ? inspectionChecklist.updateDropdown(step.title, val)
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
