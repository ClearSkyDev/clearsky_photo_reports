import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/photo_entry.dart';

class SectionedPhotoUploadScreen extends StatefulWidget {
  const SectionedPhotoUploadScreen({super.key});

  @override
  State<SectionedPhotoUploadScreen> createState() =>
      _SectionedPhotoUploadScreenState();
}

class _SectionedPhotoUploadScreenState extends State<SectionedPhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  final Map<String, List<PhotoEntry>> _sections = {
    'Address Photo': [],
    'Front of House': [],
    'Front Elevation + Accessories': [],
    'Right Elevation + Accessories': [],
    'Back Elevation + Accessories': [],
    'Backyard Damages': [],
    'Left Elevation + Accessories': [],
    'Roof Edge (Gutters, Soffits, Layers)': [],
    'Roof Slopes (Front, Right, Back, Left)': [],
    'Additional Structures': [],
  };

  Future<void> _pickImages(String section) async {
    final List<XFile> selected = await _picker.pickMultiImage();
    if (selected.isNotEmpty) {
      setState(() {
        _sections[section]!.addAll(
          selected.map((xfile) => PhotoEntry(url: xfile.path)).toList(),
        );
      });
    }
  }

  void _removePhoto(String section, int index) {
    setState(() {
      _sections[section]!.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roof Inspection Photos')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: _sections.keys.map((section) {
          final photos = _sections[section]!;
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
                        section,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _pickImages(section),
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Add Photos'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (photos.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: photos.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemBuilder: (context, index) {
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(photos[index].url, fit: BoxFit.cover),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removePhoto(section, index),
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
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
