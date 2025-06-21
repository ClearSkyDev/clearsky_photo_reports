import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class GuidedCaptureScreen extends StatefulWidget {
  const GuidedCaptureScreen({super.key});

  @override
  GuidedCaptureScreenState createState() => GuidedCaptureScreenState();
}

class GuidedCaptureScreenState extends State<GuidedCaptureScreen> {
  final List<String> captureSteps = [
    'Address Photo',
    'Front of House',
    'Front Elevation',
    'Right Elevation',
    'Back Elevation',
    'Left Elevation',
    'Roof Edge - Gutters',
    'Front Slope',
    'Right Slope',
    'Back Slope',
    'Left Slope',
    'Interior Damage (if applicable)',
    'Additional Structures',
  ];

  int currentStep = 0;
  final Map<String, File?> capturedPhotos = {};
  final ImagePicker picker = ImagePicker();

  Future<void> _takePhoto() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        capturedPhotos[captureSteps[currentStep]] = File(pickedFile.path);
      });
    }
  }

  void _nextStep() {
    if (currentStep < captureSteps.length - 1) {
      setState(() {
        currentStep++;
      });
    } else {
      _finishCapture();
    }
  }

  void _prevStep() {
    if (currentStep > 0) {
      setState(() {
        currentStep--;
      });
    }
  }

  void _finishCapture() {
    // Navigate to review or return to dashboard
    Navigator.pop(context, capturedPhotos);
  }

  @override
  Widget build(BuildContext context) {
    final stepLabel = captureSteps[currentStep];
    final photoFile = capturedPhotos[stepLabel];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guided Photo Capture'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Step ${currentStep + 1} of ${captureSteps.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              stepLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            photoFile != null
                ? Image.file(photoFile, height: 200)
                : Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(child: Text('No photo taken yet')),
                  ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture Photo'),
              onPressed: _takePhoto,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentStep > 0)
                  ElevatedButton(
                    onPressed: _prevStep,
                    child: const Text('Back'),
                  ),
                ElevatedButton(
                  onPressed: _nextStep,
                  child: Text(currentStep == captureSteps.length - 1
                      ? 'Finish'
                      : 'Next'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
