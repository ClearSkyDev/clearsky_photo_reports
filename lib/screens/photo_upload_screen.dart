import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/inspection_sections.dart';
import '../models/photo_entry.dart';
import '../models/inspection_metadata.dart';
import 'report_preview_screen.dart';

class PhotoUploadScreen extends StatefulWidget {
  final InspectionMetadata metadata;
  const PhotoUploadScreen({super.key, required this.metadata});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  late final InspectionMetadata _metadata;
  final ImagePicker _picker = ImagePicker();

  // Photos for the main structure
  late final Map<String, List<PhotoEntry>> sectionPhotos = {
    for (var s in kInspectionSections) s: [],
  };

  // Additional structures
  final List<String> additionalNames = [];
  final List<Map<String, List<PhotoEntry>>> additionalStructures = [];

  @override
  void initState() {
    super.initState();
    _metadata = widget.metadata;
  }

  Future<String> getSuggestedLabel(String path) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'Suggested Label';
  }

  Future<void> _pickImages(String section, {int? structure}) async {
    final List<XFile> selected = await _picker.pickMultiImage();
    if (selected.isNotEmpty) {
      setState(() {
        final target = structure == null
            ? sectionPhotos[section]!
            : additionalStructures[structure][section]!;
        for (var xfile in selected) {
          final entry = PhotoEntry(url: xfile.path);
          target.add(entry);
          getSuggestedLabel(xfile.path).then((label) {
            setState(() {
              entry.label = label;
            });
          });
        }
      });
    }
  }

  void _removePhoto(String section, int index, {int? structure}) {
    setState(() {
      final target = structure == null
          ? sectionPhotos[section]!
          : additionalStructures[structure][section]!;
      target.removeAt(index);
    });
  }

  void _addStructure(String name) {
    if (name.isEmpty) return;
    setState(() {
      additionalNames.add(name);
      additionalStructures.add({for (var s in kInspectionSections) s: []});
    });
  }

  void _showAddStructureDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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

  void _showLabelDialog(PhotoEntry entry) {
    final controller = TextEditingController(
        text: entry.label == 'Unlabeled' ? '' : entry.label);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Label Photo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Label'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                entry.label = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
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
    void Function(PhotoEntry) onLabel,
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
                  label: const Text('Add Photo(s)'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (photos.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: photos.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return GestureDetector(
                    onTap: () => onLabel(photo),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: Image.network(photo.url, fit: BoxFit.cover),
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
                        if (photo.label.isNotEmpty && photo.label != 'Unlabeled')
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.black54,
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                photo.label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  bool get _hasPhotos {
    for (var p in sectionPhotos.values) {
      if (p.isNotEmpty) return true;
    }
    for (var m in additionalStructures) {
      for (var p in m.values) {
        if (p.isNotEmpty) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> items = [];

    for (var section in kInspectionSections) {
      items.add(
        _buildSection(
          section,
          sectionPhotos[section]!,
          () => _pickImages(section),
          (i) => _removePhoto(section, i),
          (p) => _showLabelDialog(p),
        ),
      );
    }

    for (int i = 0; i < additionalStructures.length; i++) {
      final name = additionalNames[i];
      final sections = additionalStructures[i];
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      );
      for (var section in kInspectionSections) {
        items.add(
          _buildSection(
            '$name - $section',
            sections[section]!,
            () => _pickImages(section, structure: i),
            (idx) => _removePhoto(section, idx, structure: i),
            (p) => _showLabelDialog(p),
          ),
        );
      }
    }

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

    if (_hasPhotos) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportPreviewScreen(
                    sections: sectionPhotos,
                    additionalStructures: additionalStructures,
                    additionalNames: additionalNames,
                    metadata: _metadata,
                  ),
                ),
              );
            },
            child: const Text('Preview Report'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Image.asset('assets/images/clearsky_logo.png', height: 28),
            const SizedBox(width: 8),
            const Text('Photo Upload'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: items,
      ),
    );
  }
}
