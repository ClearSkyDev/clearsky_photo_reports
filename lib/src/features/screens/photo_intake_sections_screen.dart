import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/expandable_tile.dart';
import 'photo_label_screen.dart';

/// Default intake section names used across inspections.
const List<String> intakeSections = [
  'Address',
  'Front of Risk',
  'Elevations',
  'Edge',
  'Roof',
  'Accessories',
  'Additional Structure',
];

/// Screen showing collapsible tiles for capturing photos in each section.
class PhotoIntakeSectionsScreen extends StatefulWidget {
  const PhotoIntakeSectionsScreen({super.key});

  @override
  State<PhotoIntakeSectionsScreen> createState() => _PhotoIntakeSectionsScreenState();
}

class _PhotoIntakeSectionsScreenState extends State<PhotoIntakeSectionsScreen> {
  final ImagePicker _picker = ImagePicker();

  // Store captured images for each section.
  late final Map<String, List<XFile>> _photos = {
    for (final s in intakeSections) s: [],
  };

  Future<void> _openCamera(String section) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (!mounted || image == null) return;
    final List<LabeledImage>? labeled = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoLabelScreen(
          images: [image],
          sectionContext: section,
        ),
      ),
    );
    if (labeled != null && labeled.isNotEmpty) {
      setState(() => _photos[section]!.addAll(labeled.map((e) => e.image)));
    }
  }

  Future<void> _openGallery(String section) async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (!mounted || images.isEmpty) return;
    final List<LabeledImage>? labeled = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoLabelScreen(
          images: images,
          sectionContext: section,
        ),
      ),
    );
    if (labeled != null && labeled.isNotEmpty) {
      setState(() => _photos[section]!.addAll(labeled.map((e) => e.image)));
    }
  }

  bool _hasPhotos(String section) => _photos[section]!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Intake')),
      body: ListView(
        children: [
          for (final section in intakeSections)
            ExpandableTile(
              title: section,
              onTakePhoto: () => _openCamera(section),
              onChooseGallery: () => _openGallery(section),
              isCompleted: _hasPhotos(section),
            ),
        ],
      ),
    );
  }
}
