import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/label_suggestion_service.dart';
import '../../core/utils/crop_preferences.dart';
import '../../core/utils/square_cropper.dart';

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

    final enforce = await CropPreferences.isEnforced();
    final processed =
        enforce ? await SquareCropper.crop(picked) : picked;

    final bytes = await processed.readAsBytes();
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
      photoUri: processed.path,
    );

    final newPhoto = {
      'localPath': processed.path,
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
    final approved = photo['approved'] as bool? ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Image.file(File(photo['localPath']), width: 50),
        title: TextFormField(
          initialValue: photo['userLabel'] as String? ?? '',
          onChanged: (val) =>
              setState(() => _capturedPhotos[index]['userLabel'] = val),
          decoration: const InputDecoration(
            labelText: 'Suggested Label',
            suffixIcon: Icon(Icons.lightbulb),
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            approved ? Icons.check_circle : Icons.check_circle_outline,
            color: approved ? Colors.green : null,
          ),
          tooltip: 'Approve Label',
          onPressed: () => setState(() {
            _capturedPhotos[index]['approved'] = !approved;
          }),
        ),
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
