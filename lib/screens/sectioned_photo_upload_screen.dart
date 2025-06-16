import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderables/reorderables.dart';

import '../models/photo_entry.dart';

class SectionedPhotoUploadScreen extends StatefulWidget {
  const SectionedPhotoUploadScreen({super.key});

  @override
  State<SectionedPhotoUploadScreen> createState() =>
      _SectionedPhotoUploadScreenState();
}

class _SectionedPhotoUploadScreenState extends State<SectionedPhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  // Base section names used for the main structure and any additional structures
  final List<String> _baseSections = [
    'Address Photo',
    'Front of House',
    'Front Elevation + Accessories',
    'Right Elevation + Accessories',
    'Back Elevation + Accessories',
    'Backyard Damages',
    'Left Elevation + Accessories',
    'Roof Edge (Gutters, Soffits, Layers)',
    'Roof Slopes (Front, Right, Back, Left)',
  ];

  // Photos for the main structure
  late final Map<String, List<PhotoEntry>> _sections = {
    for (var s in _baseSections) s: [],
  };

  // Nested map for additional structures: {structureName: {sectionName: photos}}
  final Map<String, Map<String, List<PhotoEntry>>> _additionalStructures = {};

  Future<void> _pickImages(String section, [String? structure]) async {
    final List<XFile> selected = await _picker.pickMultiImage();
    if (selected.isNotEmpty) {
      setState(() {
        final target = structure == null
            ? _sections[section]!
            : _additionalStructures[structure]![section]!;
        target.addAll(
          selected.map((xfile) => PhotoEntry(url: xfile.path)).toList(),
        );
      });
    }
  }

  void _removePhoto(String section, int index, [String? structure]) {
    setState(() {
      final target = structure == null
          ? _sections[section]!
          : _additionalStructures[structure]![section]!;
      target.removeAt(index);
    });
  }

  void _addStructure(String name) {
    if (name.isEmpty || _additionalStructures.containsKey(name)) return;
    setState(() {
      _additionalStructures[name] = {for (var s in _baseSections) s: []};
    });
  }

  void _showAddStructureDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Structure'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Structure Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _addStructure(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String label,
    List<PhotoEntry> photos,
    VoidCallback onAdd,
    void Function(int) onRemove,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Add Photos'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (photos.isNotEmpty)
              ReorderableWrap(
                needsLongPressDraggable: true,
                spacing: 6,
                runSpacing: 6,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    final item = photos.removeAt(oldIndex);
                    photos.insert(newIndex, item);
                  });
                },
                children: [
                  for (int index = 0; index < photos.length; index++)
                    Stack(
                      key: ValueKey('${photos[index].url}-$index'),
                      fit: StackFit.expand,
                      children: [
                        Image.network(photos[index].url, fit: BoxFit.cover),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => onRemove(index),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: const Icon(Icons.drag_handle, color: Colors.white),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];

    _sections.forEach((section, photos) {
      items.add(
        _buildSection(
          section,
          photos,
          () => _pickImages(section),
          (i) => _removePhoto(section, i),
        ),
      );
    });

    _additionalStructures.forEach((structure, sections) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            structure,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      );
      sections.forEach((section, photos) {
        final label = '$structure - $section';
        items.add(
          _buildSection(
            label,
            photos,
            () => _pickImages(section, structure),
            (i) => _removePhoto(section, i, structure),
          ),
        );
      });
    });

    items.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ElevatedButton.icon(
          onPressed: _showAddStructureDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Structure'),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Roof Inspection Photos')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: items,
      ),
    );
  }
}
