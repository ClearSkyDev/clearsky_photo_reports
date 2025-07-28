import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/utils/logging.dart';

/// Simple screen for testing photo capture and upload.
class TestPhotoUploadScreen extends StatefulWidget {
  const TestPhotoUploadScreen({super.key});

  @override
  State<TestPhotoUploadScreen> createState() => _TestPhotoUploadScreenState();
}

class _TestPhotoUploadScreenState extends State<TestPhotoUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null && mounted) {
        setState(() => _image = picked);
      }
    } catch (e) {
      logger().d('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;
    try {
      final file = File(_image!.path);
      final name = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref('test_uploads/$name.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      logger().d('Uploaded to $url');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload successful')),
      );
    } catch (e) {
      logger().d('Upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Upload')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Select Image'),
            ),
            const SizedBox(height: 16),
            if (_image != null) Image.file(File(_image!.path), height: 200),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _image == null ? null : _uploadImage,
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
