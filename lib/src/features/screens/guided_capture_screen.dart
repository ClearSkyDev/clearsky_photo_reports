import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/label_suggestion_service.dart';

class GuidedCaptureScreen extends StatefulWidget {
  final String inspectionId;
  final String section;

  const GuidedCaptureScreen({
    super.key,
    required this.inspectionId,
    this.section = 'General',
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

    final suggestedLabel = await LabelSuggestionService.suggestLabel(
      sectionPrefix: widget.section,
      photoUri: picked.path,
    );

    final newPhoto = {
      'localPath': picked.path,
      'filename': filename,
      'sectionPrefix': widget.section,
      'userLabel': suggestedLabel,
      'aiSuggestedLabel': suggestedLabel,
      'approved': false,
      'data': bytes,
      'url': url,
    };

    setState(() {
      _capturedPhotos.add(newPhoto);
    });
  }

  Widget _buildPhoto(int index, Map<String, dynamic> photo) {
    final controller = TextEditingController(text: photo['userLabel'] as String? ?? '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Image.memory(photo['data'] as Uint8List, height: 200),
          TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Label this photo'),
            onChanged: (val) {
              setState(() {
                _capturedPhotos[index]['userLabel'] = val;
              });
            },
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
          ..._capturedPhotos.asMap().entries.map(
            (entry) => _buildPhoto(entry.key, entry.value),
          ),
        ],
      ),
    );
  }
}
