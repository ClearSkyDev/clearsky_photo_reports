import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_theme.dart';
import '../../core/models/inspection_photo.dart';


/// Screen for previewing a photo and building a label using QuickTags.
class PhotoLabelScreen extends StatefulWidget {
  final List<XFile> images;
  final String sectionContext;

  const PhotoLabelScreen({
    super.key,
    required this.images,
    required this.sectionContext,
  });

  @override
  State<PhotoLabelScreen> createState() => _PhotoLabelScreenState();
}

class _PhotoLabelScreenState extends State<PhotoLabelScreen> {
  final ImagePicker _picker = ImagePicker();

  late List<XFile> _images;
  late List<Set<String>> _tags;
  late List<TextEditingController> _controllers;
  late final List<String> _itemTags;
  final List<String> _directionTags = const ['Front', 'Right', 'Back', 'Left'];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _images = [...widget.images];
    _tags = [for (final _ in _images) <String>{}];
    _controllers = [for (final _ in _images) TextEditingController()];
    _itemTags = _suggestItemTags(widget.sectionContext);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _suggestItemTags(String section) {
    final lower = section.toLowerCase();
    if (lower.contains('roof')) {
      return ['Shingle', 'Vent', 'Debris Damage'];
    }
    if (lower.contains('front')) {
      return ['Door', 'Window', 'Downspout'];
    }
    if (lower.contains('elevation')) {
      return ['Window', 'Door', 'Siding'];
    }
    return ['General', 'Damage'];
  }

  void _toggle(String tag, bool selected) {
    setState(() {
      final tags = _tags[_currentIndex];
      if (selected) {
        tags.add(tag);
      } else {
        tags.remove(tag);
      }
      _controllers[_currentIndex].text = tags.join(' – ');
    });
  }

  void _save() {
    final photos = <InspectionPhoto>[];
    for (var i = 0; i < _images.length; i++) {
      final tags = _controllers[i]
          .text
          .split(' – ')
          .where((e) => e.trim().isNotEmpty)
          .toList();
      final photo = InspectionPhoto(
        imagePath: _images[i].path,
        section: widget.sectionContext,
        tags: tags,
        timestamp: DateTime.now(),
      );
      inspectionPhotos.add(photo);
      photos.add(photo);
    }
    Navigator.pop(context, photos);
  }

  Future<void> _addPhotos() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final baseTags = {..._tags[_currentIndex]};
    final baseLabel = _controllers[_currentIndex].text;
    if (source == ImageSource.camera) {
      final XFile? img = await _picker.pickImage(source: ImageSource.camera);
      if (img == null) return;
      setState(() {
        _images.add(img);
        _tags.add({...baseTags});
        _controllers.add(TextEditingController(text: baseLabel));
        _currentIndex = _images.length - 1;
      });
    } else {
      final List<XFile> imgs = await _picker.pickMultiImage();
      if (imgs.isEmpty) return;
      setState(() {
        for (final x in imgs) {
          _images.add(x);
          _tags.add({...baseTags});
          _controllers.add(TextEditingController(text: baseLabel));
        }
        _currentIndex = _images.length - 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Label Photos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                itemCount: _images.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  final file = _images[index];
                  final tags = _tags[index];
                  final controller = _controllers[index];
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Image.file(File(file.path), height: 250),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (final tag in [..._directionTags, ..._itemTags])
                              FilterChip(
                                label: Text(tag),
                                selected: tags.contains(tag),
                                onSelected: (val) {
                                  _currentIndex = index;
                                  _toggle(tag, val);
                                },
                                selectedColor:
                                    AppTheme.clearSkyBlue.withValues(alpha: (0.2 * 255).round()),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            labelText: 'Label',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addPhotos,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

