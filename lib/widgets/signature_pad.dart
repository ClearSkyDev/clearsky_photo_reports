import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:path/path.dart' as p;

/// A simple widget that lets the user draw a signature and save it as PNG.
///
/// The [onSave] callback provides the generated PNG bytes when the user taps
/// the Save button.
class SignaturePad extends StatefulWidget {
  final void Function(Uint8List bytes, File file)? onSave;
  const SignaturePad({super.key, this.onSave});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  late final SignatureController _controller;
  Uint8List? _signatureBytes;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.isEmpty) return;
    final bytes = await _controller.toPngBytes();
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'signature.png'));
    await file.writeAsBytes(bytes);

    setState(() {
      _signatureBytes = bytes;
    });
    widget.onSave?.call(bytes, file);
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _signatureBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
          ),
          child: Signature(
            controller: _controller,
            backgroundColor: Colors.white,
          ),
        ),
        if (_signatureBytes != null) ...[
          const SizedBox(height: 8),
          Image.memory(
            _signatureBytes!,
            height: 100,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: _clear,
              child: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }
}
