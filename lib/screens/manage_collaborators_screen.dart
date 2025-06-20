import 'package:flutter/material.dart';

import '../models/saved_report.dart';
import '../models/report_collaborator.dart';

class ManageCollaboratorsScreen extends StatefulWidget {
  final SavedReport report;
  const ManageCollaboratorsScreen({super.key, required this.report});

  @override
  State<ManageCollaboratorsScreen> createState() =>
      _ManageCollaboratorsScreenState();
}

class _ManageCollaboratorsScreenState extends State<ManageCollaboratorsScreen> {
  late List<ReportCollaborator> _collaborators;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  CollaboratorRole _role = CollaboratorRole.viewer;

  @override
  void initState() {
    super.initState();
    _collaborators = List.from(widget.report.collaborators);
  }

  void _add() {
    final id = _idController.text.trim();
    final name = _nameController.text.trim();
    if (id.isEmpty || name.isEmpty) return;
    setState(() {
      _collaborators.add(ReportCollaborator(id: id, name: name, role: _role));
      _idController.clear();
      _nameController.clear();
      _role = CollaboratorRole.viewer;
    });
  }

  void _remove(int index) {
    setState(() {
      _collaborators.removeAt(index);
    });
  }

  void _save() {
    Navigator.pop(context, _collaborators);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Collaborators')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _collaborators.length,
                itemBuilder: (context, index) {
                  final c = _collaborators[index];
                  return ListTile(
                    title: Text(c.name),
                    subtitle: Text(c.role.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Remove',
                      onPressed: () => _remove(index),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(labelText: 'User ID'),
            ),
            DropdownButtonFormField<CollaboratorRole>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: CollaboratorRole.values
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _role = val ?? CollaboratorRole.viewer),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _add, child: const Text('Add')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
