import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';

import '../widgets/signature_pad.dart';

/// Screen that allows the inspector to draw a new signature and
/// return the PNG bytes when finished.
class CaptureSignatureScreen extends StatefulWidget {
  const CaptureSignatureScreen({super.key});

  @override
  State<CaptureSignatureScreen> createState() => _CaptureSignatureScreenState();
}

class _CaptureSignatureScreenState extends State<CaptureSignatureScreen> {
  Uint8List? _bytes;

  void _onSave(Uint8List bytes, File file) {
    setState(() {
      _bytes = bytes;
    });
  }

  void _useSignature() {
    if (_bytes != null) {
      Navigator.of(context).pop(_bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Re-sign')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SignaturePad(onSave: _onSave),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _bytes != null ? _useSignature : null,
              child: const Text('Use Signature'),
            ),
          ],
        ),
      ),
    );
  }
}
