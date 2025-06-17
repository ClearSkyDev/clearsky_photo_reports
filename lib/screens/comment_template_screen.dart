import 'package:flutter/material.dart';
import '../utils/comment_template_store.dart';

class CommentTemplateScreen extends StatefulWidget {
  const CommentTemplateScreen({super.key});

  @override
  State<CommentTemplateScreen> createState() => _CommentTemplateScreenState();
}

class _CommentTemplateScreenState extends State<CommentTemplateScreen> {
  List<String> _templates = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await CommentTemplateStore.loadTemplates();
    setState(() => _templates = items);
  }

  Future<void> _save() async {
    await CommentTemplateStore.saveTemplates(_templates);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Templates saved')));
    }
  }

  void _edit([String? template, int? index]) {
    final controller = TextEditingController(text: template ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(index == null ? 'Add Template' : 'Edit Template'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Text'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                if (index == null) {
                  _templates.add(controller.text);
                } else {
                  _templates[index] = controller.text;
                }
              });
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
      appBar: AppBar(title: const Text('Comment Templates')),
      body: ListView.builder(
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final t = _templates[index];
          return ListTile(
            title: Text(t),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _edit(t, index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() => _templates.removeAt(index));
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: _save,
          child: const Text('Save Templates'),
        ),
      ),
    );
  }
}
