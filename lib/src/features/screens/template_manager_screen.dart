import 'package:flutter/material.dart';
import '../../core/models/report_template.dart';
import '../../core/utils/template_store.dart';

class TemplateManagerScreen extends StatefulWidget {
  const TemplateManagerScreen({super.key});

  @override
  State<TemplateManagerScreen> createState() => _TemplateManagerScreenState();
}

class _TemplateManagerScreenState extends State<TemplateManagerScreen> {
  List<ReportTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await TemplateStore.loadTemplates();
    if (!mounted) return;
    setState(() => _templates = items);
  }

  Future<void> _save(ReportTemplate template) async {
    await TemplateStore.saveTemplate(template);
    await _load();
  }

  Future<void> _delete(String id) async {
    await TemplateStore.deleteTemplate(id);
    await _load();
  }

  void _editTemplate([ReportTemplate? template]) {
    final isNew = template == null;
    final id = template?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final nameController = TextEditingController(text: template?.name ?? '');
    final sectionsController = TextEditingController(
        text: template?.sections.join('\n') ?? 'Address Photo');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isNew ? 'New Template' : 'Edit Template'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: sectionsController,
                decoration: const InputDecoration(
                  labelText: 'Sections (one per line)',
                ),
                maxLines: 6,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final template = ReportTemplate(
                id: id,
                name: nameController.text.trim(),
                sections: sectionsController.text
                    .split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
              );
              _save(template);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Templates')),
      body: ListView.builder(
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final t = _templates[index];
          return ListTile(
            title: Text(t.name),
            subtitle: Text('${t.sections.length} sections'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Duplicate Template',
                  onPressed: () {
                    final copy = t.copyWith(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: '${t.name} Copy',
                    );
                    _save(copy);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Template',
                  onPressed: () => _editTemplate(t),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete Template',
                  onPressed: () => _delete(t.id),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _editTemplate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
