import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_theme.dart';

/// Model representing an image and its associated label tags.
class LabeledImage {
  final XFile image;
  final Set<String> tags;

  LabeledImage(this.image, [Set<String>? tags]) : tags = tags ?? {};

  /// Returns tags joined with an en dash.
  String get label => tags.join(' – ');
}

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

  late List<LabeledImage> _images;
  late final List<String> _itemTags;
  final List<String> _directionTags = const ['Front', 'Right', 'Back', 'Left'];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _images = [for (final img in widget.images) LabeledImage(img)];
    _itemTags = _suggestItemTags(widget.sectionContext);
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
      final tags = _images[_currentIndex].tags;
      if (selected) {
        tags.add(tag);
      } else {
        tags.remove(tag);
      }
    });
  }

  void _save() {
    Navigator.pop(context, _images);
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

    final baseTags = {..._images[_currentIndex].tags};
    if (source == ImageSource.camera) {
      final XFile? img = await _picker.pickImage(source: ImageSource.camera);
      if (img == null) return;
      setState(() {
        _images.add(LabeledImage(img, baseTags));
        _currentIndex = _images.length - 1;
      });
    } else {
      final List<XFile> imgs = await _picker.pickMultiImage();
      if (imgs.isEmpty) return;
      setState(() {
        for (final x in imgs) {
          _images.add(LabeledImage(x, {...baseTags}));
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
                  final labeled = _images[index];
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Image.file(File(labeled.image.path), height: 250),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          children: [
                            for (final tag in [..._directionTags, ..._itemTags])
                              FilterChip(
                                label: Text(tag),
                                selected: labeled.tags.contains(tag),
                                onSelected: (val) {
                                  _currentIndex = index;
                                  _toggle(tag, val);
                                },
                                selectedColor:
                                    AppTheme.clearSkyBlue.withOpacity(0.2),
                              ),
                          ],
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

