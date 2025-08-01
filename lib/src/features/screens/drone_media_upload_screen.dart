import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/crop_preferences.dart';
import '../../core/utils/square_cropper.dart';
import 'dart:io';
import '../../core/models/photo_entry.dart';

class DroneMediaUploadScreen extends StatefulWidget {
  const DroneMediaUploadScreen({super.key});

  @override
  State<DroneMediaUploadScreen> createState() => _DroneMediaUploadScreenState();
}

class _DroneMediaUploadScreenState extends State<DroneMediaUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<PhotoEntry> _photos = [];
  SourceType _type = SourceType.drone;
  String _section = 'General';

  Future<void> _pick() async {
    final selected = await _picker.pickMultiImage();
    if (selected.isEmpty) return;
    final enforce = await CropPreferences.isEnforced();
    final List<XFile> processed = [];
    if (enforce) {
      for (final x in selected) {
        processed.add(await SquareCropper.crop(x));
      }
    } else {
      processed.addAll(selected);
    }
    setState(() {
      _photos.addAll(processed.map((x) => PhotoEntry(
            url: x.path,
            sourceType: _type,
            label: _section,
          )));
    });
  }

  IconData _iconFor(SourceType t) {
    switch (t) {
      case SourceType.drone:
        return Icons.flight;
      case SourceType.thermal:
        return Icons.thermostat;
      default:
        return Icons.camera_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drone Media Upload')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                DropdownButton<SourceType>(
                  value: _type,
                  onChanged: (v) => setState(() => _type = v!),
                  items: [
                    const DropdownMenuItem(
                        value: SourceType.drone, child: Text('Drone')),
                    const DropdownMenuItem(
                        value: SourceType.thermal, child: Text('Thermal')),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Section'),
                    onChanged: (v) => _section = v,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_a_photo),
                  tooltip: 'Add Photos',
                  onPressed: _pick,
                )
              ],
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
              itemCount: _photos.length,
              itemBuilder: (context, i) => Stack(
                fit: StackFit.expand,
                children: [
                  _photos[i].url.startsWith('http')
                      ? Image.network(_photos[i].url, fit: BoxFit.cover)
                      : Image.file(File(_photos[i].url), fit: BoxFit.cover),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Icon(_iconFor(_photos[i].sourceType),
                        color: Colors.white),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
