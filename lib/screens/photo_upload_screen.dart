import 'report_preview_screen.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/photo_entry.dart';

class PhotoUploadScreen extends StatefulWidget {
  const PhotoUploadScreen({super.key});

  @override
  _PhotoUploadScreenState createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<PhotoEntry> _photos = [];

  Future<void> _pickImages() async {
    final List<XFile> selected = await _picker.pickMultiImage();
    if (selected != null && selected.isNotEmpty) {
      setState(() {
        _photos.addAll(
          selected.map((xfile) => PhotoEntry(url: xfile.path)).toList(),
        );
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Photo Upload')),
      body: Column(
        children: [
          SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _pickImages,
            icon: Icon(Icons.add_a_photo),
            label: Text("Pick Photos"),
          ),
          SizedBox(height: 10),
          Expanded(child: GridView.builder(
              padding: EdgeInsets.all(8),
              itemCount: _photos.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
             itemBuilder: (context, index) {
  return Column(
    children: [
      Stack(
        children: [
          Image.network(
            _photos[index].url,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      TextField(
        decoration: InputDecoration(
          hintText: 'Enter label',
          contentPadding: EdgeInsets.symmetric(horizontal: 8),
        ),
        onChanged: (value) {
          setState(() {
            _photos[index].label = value;
          });
        },
      ),
    ],
  );
}
            ),
            if (_photos.is7NotEmpty) {
return  Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportPreviewScreen(photos: _photos),
          ),
        );
      },
      child: const Text('Preview Report'),
    ),
  ),

          ),
        ],
      ),
    );
  }
}
