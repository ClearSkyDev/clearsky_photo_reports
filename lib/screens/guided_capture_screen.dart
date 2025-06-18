import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/photo_entry.dart';
import '../models/inspection_metadata.dart';
import '../models/inspection_sections.dart';
import '../models/report_template.dart';
import '../models/photo_source.dart';

class GuidedCaptureScreen extends StatefulWidget {
  final InspectionMetadata metadata;
  final ReportTemplate? template;
  const GuidedCaptureScreen({super.key, required this.metadata, this.template});

  @override
  State<GuidedCaptureScreen> createState() => _GuidedCaptureScreenState();
}

class _GuidedCaptureScreenState extends State<GuidedCaptureScreen> {
  late final List<String> _sections;
  final ImagePicker _picker = ImagePicker();
  late final Map<String, List<PhotoEntry>> _sectionPhotos;
  int _current = 0;
  bool _showPrompt = true;

  @override
  void initState() {
    super.initState();
    _sections = widget.template?.sections ??
        sectionsForType(widget.metadata.inspectionType);
    _sectionPhotos = {for (var s in _sections) s: []};
  }

  Future<void> _pickImages() async {
    final selected = await _picker.pickMultiImage();
    if (selected.isEmpty) return;
    final section = _sections[_current];
    setState(() {
      final target = _sectionPhotos[section]!;
      for (final x in selected) {
        target.add(PhotoEntry(
          url: x.path,
          capturedAt: DateTime.now(),
          label: section,
          sourceType: SourceType.camera,
        ));
      }
      _showPrompt = false;
    });
  }

  void _next() {
    if (_current < _sections.length - 1) {
      setState(() {
        _current++;
        _showPrompt = true;
      });
    } else {
      Navigator.pop(context, _sectionPhotos);
    }
  }

  void _jumpTo(int index) {
    setState(() {
      _current = index;
      _showPrompt = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final section = _sections[_current];
    final completed =
        _sectionPhotos.values.where((e) => e.isNotEmpty).length;
    final progress = completed / _sections.length;
    final prompt = widget.template?.photoPrompts[section];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guided Capture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Jump to Section',
            onPressed: () async {
              final choice = await showModalBottomSheet<int>(
                context: context,
                builder: (_) => ListView.builder(
                  itemCount: _sections.length,
                  itemBuilder: (_, i) => ListTile(
                    title: Text(_sections[i]),
                    trailing: _sectionPhotos[_sections[i]]!.isNotEmpty
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => Navigator.pop(context, i),
                  ),
                ),
              );
              if (choice != null) _jumpTo(choice);
            },
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: progress),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Step ${_current + 1} of ${_sections.length}: $section',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (prompt != null && _showPrompt)
            Dismissible(
              key: ValueKey(section),
              onDismissed: (_) => setState(() => _showPrompt = false),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(prompt),
                ),
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _sectionPhotos[section]!.length,
              itemBuilder: (_, i) => Image.network(
                _sectionPhotos[section]![i].url,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _pickImages,
                  child: const Text('Add Photo'),
                ),
                TextButton(
                  onPressed: _next,
                  child:
                      Text(_current == _sections.length - 1 ? 'Finish' : 'Skip'),
                ),
                ElevatedButton(
                  onPressed: _next,
                  child: Text(
                      _current == _sections.length - 1 ? 'Done' : 'Next'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
