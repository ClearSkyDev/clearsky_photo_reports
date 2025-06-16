import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderables/reorderables.dart';

import '../models/inspection_sections.dart';
import '../models/photo_entry.dart';
import '../models/inspection_metadata.dart';
import '../models/inspected_structure.dart';
import '../models/checklist.dart';
import '../models/report_template.dart';
import '../utils/label_suggestion.dart';
import '../utils/damage_classification.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'report_preview_screen.dart';
import 'signature_screen.dart';
import 'photo_map_screen.dart';
import 'photo_detail_screen.dart';
import '../utils/change_history.dart';
import '../models/report_change.dart';

class PhotoUploadScreen extends StatefulWidget {
  final InspectionMetadata metadata;
  final ReportTemplate? template;
  const PhotoUploadScreen({super.key, required this.metadata, this.template});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  late final InspectionMetadata _metadata;
  final ImagePicker _picker = ImagePicker();

  bool _autoLabeling = false;
  int _autoLabelRemaining = 0;
  int _autoLabelTotal = 0;

  final List<InspectedStructure> _structures = [];
  int _currentStructure = 0;

  @override
  void initState() {
    super.initState();
    _metadata = widget.metadata;
    final sections = widget.template?.sections ?? kInspectionSections;
    _structures.add(
      InspectedStructure(
        name: 'Main Structure',
        sectionPhotos: {for (var s in sections) s: []},
      ),
    );
  }


  Future<void> _pickImages(String section, {int? structure}) async {
    final List<XFile> selected = await _picker.pickMultiImage();
    if (selected.isNotEmpty) {
      final position = await _getPosition();
      setState(() {
        final index = structure ?? _currentStructure;
        final target = _structures[index].sectionPhotos[section]!;
        final wasEmpty = target.isEmpty;
        for (var xfile in selected) {
          final entry = PhotoEntry(
            url: xfile.path,
            capturedAt: DateTime.now(),
            latitude: position?.latitude,
            longitude: position?.longitude,
            label: '',
            labelLoading: true,
            damageLoading: true,
          );
          target.add(entry);
          getSuggestedLabel(entry, section, _metadata).then((label) {
            setState(() {
              entry
                ..label = label
                ..labelLoading = false;
            });
          });
          getDamageType(entry, section, _metadata).then((damage) {
            setState(() {
              entry
                ..damageType = damage
                ..damageLoading = false;
            });
          });
        }
        if (wasEmpty) {
          if (section == 'Address Photo') {
            inspectionChecklist.markComplete('Address Photo');
          } else {
            inspectionChecklist.markComplete('Elevation Photos');
          }
        }
      });
    }
  }

  Future<Position?> _getPosition() async {
    try {
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  void _openMap(double lat, double lng) {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _removePhoto(String section, int index, {int? structure}) {
    setState(() {
      final idx = structure ?? _currentStructure;
      final target = _structures[idx].sectionPhotos[section]!;
      target.removeAt(index);
    });
  }

  void _addStructure(String name) {
    if (name.isEmpty) return;
    setState(() {
      _structures.add(
        InspectedStructure(
            name: name,
            sectionPhotos: {
              for (var s in widget.template?.sections ?? kInspectionSections) s: []
            }),
      );
      _currentStructure = _structures.length - 1;
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
    final noteController = TextEditingController(text: entry.note);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Photo Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Label',
                hintText: entry.labelLoading ? 'Generating...' : null,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Inspector Note'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: [
                for (final n in ['No damage found', 'Minor damage', 'Severe damage'])
                  ActionChip(
                    label: Text(n),
                    onPressed: () => noteController.text = n,
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                final before = {
                  'label': entry.label,
                  'note': entry.note,
                };
                entry
                  ..label = controller.text
                  ..labelLoading = false;
                entry.note = noteController.text;
                changeHistory.add(
                  ReportChange(
                    type: 'photo_edit',
                    target: entry.url,
                    before: before,
                    after: {
                      'label': entry.label,
                      'note': entry.note,
                    },
                  ),
                );
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
    for (var struct in _structures) {
      struct.sectionPhotos.forEach((section, photos) {
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
            if (widget.template?.photoPrompts[label] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Text(
                  widget.template!.photoPrompts[label]!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
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
                      onLongPress: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PhotoDetailScreen(entry: photos[index]),
                          ),
                        );
                        if (updated == true) setState(() {});
                      },
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
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      photos[index].label,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      photos[index]
                                          .capturedAt
                                          .toLocal()
                                          .toString()
                                          .split('.').first,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                    if (photos[index].latitude != null &&
                                        photos[index].longitude != null)
                                      GestureDetector(
                                        onTap: () => _openMap(
                                            photos[index].latitude!,
                                            photos[index].longitude!),
                                        child: Text(
                                          '${photos[index].latitude!.toStringAsFixed(4)}, ${photos[index].longitude!.toStringAsFixed(4)}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          if (photos[index].damageLoading)
                            Positioned(
                              bottom: 20,
                              left: 0,
                              child: Container(
                                color: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: const Text(
                                  'Detecting...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            )
                          else if (photos[index].damageType.isNotEmpty && photos[index].damageType != 'Unknown')
                            Positioned(
                              bottom: 20,
                              left: 0,
                              child: Container(
                                color: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Text(
                                  photos[index].damageType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
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
    for (var s in _structures) {
      for (var p in s.sectionPhotos.values) {
        if (p.isNotEmpty) return true;
      }
    }
    return false;
  }

  List<PhotoEntry> get _gpsPhotos {
    final List<PhotoEntry> result = [];
    for (var s in _structures) {
      for (var photos in s.sectionPhotos.values) {
        for (var p in photos) {
          if (p.latitude != null && p.longitude != null) {
            result.add(p);
          }
        }
      }
    }
    return result;
  }

  void _undoLastChange() {
    final change = changeHistory.undo();
    if (change == null) return;
    if (change.type == 'photo_edit') {
      for (var struct in _structures) {
        for (var photos in struct.sectionPhotos.values) {
          for (var p in photos) {
            if (p.url == change.target) {
              setState(() {
                p.label = change.before['label'] ?? p.label;
                p.note = change.before['note'] ?? p.note;
              });
              return;
            }
          }
        }
      }
    }
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


    for (var section in widget.template?.sections ?? kInspectionSections) {
      final photos = _structures[_currentStructure].sectionPhotos[section]!;
      items.add(
        _buildSection(
          section,
          photos,
          () => _pickImages(section),
          (i) => _removePhoto(section, i),
          (p) => _showLabelDialog(p),
        ),
      );
    }

    items.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: DropdownButton<int>(
                value: _currentStructure,
                onChanged: (val) => setState(() => _currentStructure = val!),
                items: [
                  for (int i = 0; i < _structures.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(_structures[i].name),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _showAddStructureDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Structure'),
            ),
          ],
        ),
      ),
    );

    if (_gpsPhotos.isNotEmpty) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PhotoMapScreen(photos: _gpsPhotos),
                ),
              );
            },
            child: const Text('View Inspection Map'),
          ),
        ),
      );
    }

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
                    structures: _structures,
                    metadata: _metadata,
                    template: widget.template,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undoLastChange,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: items,
      ),
    );
  }
}
