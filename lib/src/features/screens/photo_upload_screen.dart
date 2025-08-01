import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/crop_preferences.dart';
import '../../core/utils/square_cropper.dart';
import 'dart:io';
import '../../core/models/photo_entry.dart';
import '../../core/models/inspection_metadata.dart';
import '../../core/utils/logging.dart';
import '../../core/models/report_template.dart';
import 'report_preview_screen.dart';

class PhotoUploadScreen extends StatefulWidget {
  final InspectionMetadata metadata;
  final ReportTemplate? template;
  const PhotoUploadScreen({
    super.key,
    required this.metadata,
    this.template,
  });

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<PhotoEntry> _photos = [];

  Future<void> _pickImages() async {
    logger().d('[PhotoUploadScreen] Picking images');
    final List<XFile> selected = await _picker.pickMultiImage();
    if (selected.isNotEmpty) {
      final enforce = await CropPreferences.isEnforced();
      final List<XFile> processed = [];
      if (enforce) {
        for (final x in selected) {
          processed.add(await SquareCropper.crop(x));
        }
      } else {
        processed.addAll(selected);
      }
      if (!mounted) return;
      setState(() {
        _photos.addAll(
          processed.map((xfile) => PhotoEntry(url: xfile.path)).toList(),
        );
      });
      logger().d('[PhotoUploadScreen] Added ${processed.length} photos');
    }
  }

  void _removePhoto(int index) {
    logger().d('[PhotoUploadScreen] Removing photo $index');
    setState(() {
      _photos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    logger().d('[PhotoUploadScreen] build');
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Upload')),
      body: Column(
        children: [
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_a_photo),
            label: const Text("Pick Photos"),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Image.file(
                      File(_photos[index].url),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removePhoto(index),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child:
                              Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Enter label',
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _photos[index].label = value;
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ElevatedButton(
              onPressed: () {
                if (_photos.isNotEmpty) {
                  logger().d('[PhotoUploadScreen] Navigating to preview');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportPreviewScreen(
                        photos: _photos,
                        metadata: widget.metadata,
                        template: widget.template,
                      ),
                    ),
                  );
                }
              },
              child: const Text('Preview Report'),
            ),
          ),
        ],
      ),
    );
  }
}
