import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/inspection_metadata.dart';
import '../models/photo_entry.dart';
import 'report_preview_screen.dart';
import '../widgets/signature_pad.dart';

class SignatureScreen extends StatefulWidget {
  final InspectionMetadata metadata;
  final Map<String, List<PhotoEntry>> sections;
  final List<Map<String, List<PhotoEntry>>> additionalStructures;
  final List<String> additionalNames;

  const SignatureScreen({
    super.key,
    required this.metadata,
    required this.sections,
    required this.additionalStructures,
    required this.additionalNames,
  });

  @override
  State<SignatureScreen> createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreen> {
  Uint8List? _signatureBytes;
  File? _signatureFile;

  void _onSave(Uint8List bytes, File file) {
    setState(() {
      _signatureBytes = bytes;
      _signatureFile = file;
    });
  }

  void _continue() {
    if (_signatureBytes == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportPreviewScreen(
          sections: widget.sections,
          additionalStructures: widget.additionalStructures,
          additionalNames: widget.additionalNames,
          metadata: widget.metadata,
          signature: _signatureBytes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Sign Report'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SignaturePad(onSave: _onSave),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signatureBytes != null ? _continue : null,
              child: const Text('Continue to Preview'),
            ),
          ],
        ),
      ),
    );
  }
}
