import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GuidedCaptureScreen extends StatefulWidget {
  final String inspectionId;

  const GuidedCaptureScreen({
    super.key,
    required this.inspectionId,
  });

  @override
  GuidedCaptureScreenState createState() => GuidedCaptureScreenState();
}

class GuidedCaptureScreenState extends State<GuidedCaptureScreen> {
  final List<Map<String, dynamic>> _capturedPhotos = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _capturePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final filename = DateTime.now().millisecondsSinceEpoch.toString();

    final ref = FirebaseStorage.instance
        .ref('users/$uid/inspections/${widget.inspectionId}/photos/$filename.jpg');
    final task = await ref.putData(bytes);
    final url = await task.ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('inspections')
        .doc(widget.inspectionId)
        .update({
      'photos': FieldValue.arrayUnion([url])
    });

    setState(() {
      _capturedPhotos.add({'data': bytes, 'url': url});
    });
  }

  Widget _buildPhoto(Uint8List data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Image.memory(data, height: 200),
          const TextField(
            decoration: InputDecoration(labelText: 'Label this photo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Intake')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: _capturePhoto,
            child: const Text('Take Photo'),
          ),
          ..._capturedPhotos.map((p) => _buildPhoto(p['data'] as Uint8List)),
        ],
      ),
    );
  }
}
