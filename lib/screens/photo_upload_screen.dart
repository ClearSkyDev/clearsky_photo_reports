import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderables/reorderables.dart';

import '../models/inspection_sections.dart';
import '../models/photo_entry.dart';
import '../models/inspection_metadata.dart';
import '../utils/label_suggestion.dart';
import 'report_preview_screen.dart';
import 'signature_screen.dart';

class PhotoUploadScreen extends StatefulWidget {
  final InspectionMetadata metadata;
  const PhotoUploadScreen({super.key, required this.metadata});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  late final InspectionMetadata _metadata;
  final ImagePicker _picker = ImagePicker();

  bool _autoLabeling = false;
  int _autoLabelRemaining = 0;
  int _autoLabelTotal = 0;

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


  Future<void> _pickImages(String section, {int? structure}) async {
    final List<XFile> selected = await _picker.pickMultiImage();
    if (selected.isNotEmpty) {
      setState(() {
        final target = structure == null
            ? sectionPhotos[section]!
            : additionalStructures[structure][section]!;
        for (var xfile in selected) {
          final entry =
              PhotoEntry(url: xfile.path, label: '', labelLoading: true);
          target.add(entry);
          getSuggestedLabel(entry, section, _metadata).then((label) {
            setState(() {
              entry
                ..label = label
                ..labelLoading = false;
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
        text: entry.labelLoading || entry.label == 'Unlabeled'
            ? ''
            : entry.label);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Label Photo'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Label',
            hintText: entry.labelLoading ? 'Generating...' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                entry
                  ..label = controller.text
                  ..labelLoading = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _autoLabelAll() async {
    final List<MapEntry<String, PhotoEntry>> unlabeled = [];
    sectionPhotos.forEach((section, photos) {
      for (var p in photos) {
        if (p.label.isEmpty || p.label == 'Unlabeled') {
          unlabeled.add(MapEntry(section, p));
        }
      }
    });
    for (var struct in additionalStructures) {
      struct.forEach((section, photos) {
        for (var p in photos) {
          if (p.label.isEmpty || p.label == 'Unlabeled') {
            unlabeled.add(MapEntry(section, p));
          }
        }
      });
    }

    if (unlabeled.isEmpty) return;

    setState(() {
      _autoLabeling = true;
      _autoLabelTotal = unlabeled.length;
      _autoLabelRemaining = unlabeled.length;
    });

    for (var item in unlabeled) {
      final photo = item.value;
      setState(() => photo.labelLoading = true);
      final label = await getSuggestedLabel(photo, item.key, _metadata);
      setState(() {
        photo
          ..label = label
          ..labelLoading = false;
        _autoLabelRemaining--;
      });
    }

    setState(() {
      _autoLabeling = false;
    });
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
                    GestureDetector(
                      key: ValueKey('${photos[index].url}-$index'),
                      onTap: () => onLabel(photos[index]),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Image.network(photos[index].url, fit: BoxFit.cover),
                          ),
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
                          if (photos[index].labelLoading)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.all(2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Generating...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (photos[index].label.isNotEmpty && photos[index].label != 'Unlabeled')
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.all(2),
                                child: Text(
                                  photos[index].label,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
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
                    ),
                ],
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

    items.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ElevatedButton.icon(
          onPressed: _autoLabeling ? null : _autoLabelAll,
          icon: const Icon(Icons.label_outline),
          label: Text(
            _autoLabeling ? 'Auto Labeling...' : 'Auto-Label All',
          ),
        ),
      ),
    );

    if (_autoLabeling) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: _autoLabelTotal == 0
                    ? null
                    : (_autoLabelTotal - _autoLabelRemaining) /
                        _autoLabelTotal,
              ),
              const SizedBox(height: 4),
              Text('Remaining: $_autoLabelRemaining'),
            ],
          ),
        ),
      );
    }


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
                  builder: (context) => SignatureScreen(
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
