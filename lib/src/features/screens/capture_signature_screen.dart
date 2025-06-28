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
  void _onSave(Uint8List bytes, File file) {
    if (!mounted) return;
    Navigator.of(context).pop(bytes);
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
          ],
        ),
      ),
    );
  }
}
