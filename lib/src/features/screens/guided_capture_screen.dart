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
  final ImagePicker _picker = ImagePicker();

  final List<String> _steps = const [
    'Address Photo',
    'Front Elevation',
    'Right Elevation',
    'Back Elevation',
    'Left Elevation',
    'Roof Edge',
    'Front Slope',
    'Right Slope',
    'Back Slope',
    'Left Slope',
  ];

  final String _optionalStep = 'Interior';

  late final List<Map<String, dynamic>?> _photos;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _photos = List.filled(_steps.length + 1, null);
  }

  Future<void> _capturePhoto(int index, String label) async {
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
      sectionPrefix: label,
      photoUri: processed.path,
    );

    final newPhoto = {
      'localPath': processed.path,
      'filename': filename,
      'sectionPrefix': label,
      'userLabel': suggestedLabel,
      'aiSuggestedLabel': suggestedLabel,
      'approved': false,
      'data': bytes,
      'url': url,
    };

    setState(() {
      _photos[index] = newPhoto;
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
              setState(() => _photos[index]!['userLabel'] = val),
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
            _photos[index]!['approved'] = !approved;
          }),
        ),
      ),
    );
  }

  Future<void> _nextStep() async {
    if (_photos[_step] == null) {
      final skip = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Skip Step?'),
          content: Text('No photo captured for ${_currentLabel()}. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Skip'),
            ),
          ],
        ),
      );
      if (skip != true) return;
    }
    if (_step < _steps.length) {
      setState(() => _step++);
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStep() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  String _currentLabel() {
    return _step < _steps.length ? _steps[_step] : _optionalStep;
  }

  Widget _buildCurrentStep() {
    final label = _currentLabel();
    final photo = _photos[_step];
    final optional = _step >= _steps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!optional)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Step ${_step + 1} of ${_steps.length}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ElevatedButton.icon(
          onPressed: () => _capturePhoto(_step, label),
          icon: const Icon(Icons.camera_alt),
          label: Text(photo == null ? 'Capture $label' : 'Retake $label'),
        ),
        if (photo != null) _buildPhoto(_step, photo),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_step > 0)
              TextButton(
                onPressed: _previousStep,
                child: const Text('Back'),
              ),
            ElevatedButton(
              onPressed: _nextStep,
              child: Text(_step < _steps.length ? 'Next' : 'Finish'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photo Intake')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildCurrentStep(),
      ),
    );
  }
}
